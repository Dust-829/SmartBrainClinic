import random
from typing import Tuple

def analyze_brain_image(image_path: str) -> Tuple[float, str]:
    """
    轻量级 Mock AI 脑部医学影像推理算法。
    解析给定的图像路径/文件名，返回模拟出的脑肿瘤恶性概率以及自动生成的影像学所见。
    
    :param image_path: 上传的医学图像路径 (如 /pacs/mri/patient_brain_tumor.dcm)
    :return: (肿瘤概率 0.00-0.99, AI影像报告描述)
    """
    if not image_path:
        return 0.0, "未上传影像，AI无法分析。"
        
    path_lower = image_path.lower()
    
    # 模拟深度学习特征提取：通过关键字和哈希计算概率
    if any(keyword in path_lower for keyword in ["tumor", "lesion", "hemorrhage", "cancer", "阳性", "占位"]):
        # 存在明显病灶特征
        base_prob = 0.70
        random_factor = random.uniform(0.05, 0.28)
        prob = round(base_prob + random_factor, 2)
        
        report = (
            "【AI 智能阅片结果】\n"
            f"1. 发现高密度/异常信号阴影，疑似颅内占位性病变。\n"
            f"2. 病灶边缘不规则，有轻度水肿带。\n"
            f"3. 恶性脑肿瘤预警概率: {prob*100:.1f}%\n"
            "建议：结合增强核磁共振(MRI)进一步排查，并建议立刻联系专科医生复诊。"
        )
        return prob, report
        
    elif any(keyword in path_lower for keyword in ["normal", "clear", "healthy", "阴性", "正常"]):
        # 正常
        base_prob = 0.01
        random_factor = random.uniform(0.01, 0.08)
        prob = round(base_prob + random_factor, 2)
        
        report = (
            "【AI 智能阅片结果】\n"
            f"1. 脑室、脑池形态大小正常。\n"
            f"2. 中线结构居中，未见明显异常占位性病变。\n"
            f"3. 脑肿瘤预警概率: {prob*100:.1f}% (极低风险)。"
        )
        return prob, report
        
    else:
        # 中性特征（模糊态）
        base_prob = 0.15
        random_factor = random.uniform(0.05, 0.30)
        prob = round(base_prob + random_factor, 2)
        
        report = (
            "【AI 智能阅片结果】\n"
            "1. 脑实质内未见明显典型大面积异常密度影。\n"
            "2. 局部可见少许斑片状模糊影，性质待定。\n"
            f"3. 脑肿瘤预警概率: {prob*100:.1f}%。\n"
            "建议：如患者有明显临床症状，建议随访观察或增加检查序列。"
        )
        return prob, report
