"""Attention UNet2D architecture compatible with the migrated checkpoint."""

from __future__ import annotations

import torch
from torch import nn


class SpatialTemporalAttention(nn.Module):
    def __init__(self, dim: int, num_heads: int = 4, qkv_bias: bool = False):
        super().__init__()
        self.num_heads = num_heads
        head_dim = dim // num_heads
        self.scale = head_dim**-0.5
        self.qkv = nn.Linear(dim, dim * 3, bias=qkv_bias)
        self.proj = nn.Linear(dim, dim)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        batch, channels, height, width = x.shape
        flattened = x.flatten(2).transpose(1, 2)
        qkv = self.qkv(flattened)
        qkv = qkv.reshape(batch, -1, 3, self.num_heads, channels // self.num_heads).permute(2, 0, 3, 1, 4)
        query, key, value = qkv[0], qkv[1], qkv[2]
        attention = (query @ key.transpose(-2, -1)) * self.scale
        attention = attention.softmax(dim=-1)
        output = (attention @ value).transpose(1, 2).reshape(batch, -1, channels)
        return self.proj(output).transpose(1, 2).reshape(batch, channels, height, width)


class DoubleConv(nn.Module):
    def __init__(self, in_channels: int, out_channels: int):
        super().__init__()
        self.conv = nn.Sequential(
            nn.Conv2d(in_channels, out_channels, 3, padding=1),
            nn.BatchNorm2d(out_channels),
            nn.ReLU(inplace=True),
            nn.Conv2d(out_channels, out_channels, 3, padding=1),
            nn.BatchNorm2d(out_channels),
            nn.ReLU(inplace=True),
        )

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        return self.conv(x)


class UNet2D(nn.Module):
    """Single-channel binary segmentation network used by attention_unet2d/best.pth."""

    def __init__(self, in_ch: int = 1, out_ch: int = 1):
        super().__init__()
        self.pool = nn.MaxPool2d(2)
        self.d1 = DoubleConv(in_ch, 64)
        self.d2 = DoubleConv(64, 128)
        self.d3 = DoubleConv(128, 256)
        self.d4 = DoubleConv(256, 512)
        self.spatial_temporal_attn = SpatialTemporalAttention(dim=512, num_heads=4)
        self.up4 = nn.ConvTranspose2d(512, 256, 2, stride=2)
        self.up3 = nn.ConvTranspose2d(256, 128, 2, stride=2)
        self.up2 = nn.ConvTranspose2d(128, 64, 2, stride=2)
        self.u4 = DoubleConv(512, 256)
        self.u3 = DoubleConv(256, 128)
        self.u2 = DoubleConv(128, 64)
        self.out = nn.Conv2d(64, out_ch, kernel_size=1)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        d1 = self.d1(x)
        d2 = self.d2(self.pool(d1))
        d3 = self.d3(self.pool(d2))
        d4 = self.spatial_temporal_attn(self.d4(self.pool(d3)))
        u4 = self.u4(torch.cat([self.up4(d4), d3], dim=1))
        u3 = self.u3(torch.cat([self.up3(u4), d2], dim=1))
        u2 = self.u2(torch.cat([self.up2(u3), d1], dim=1))
        return self.out(u2)
