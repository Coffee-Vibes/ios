extension Text {
    func h3Style() -> some View {
        self.font(.system(size: 16, weight: .semibold))
            .foregroundColor(AppColor.foreground)
    }
    
    func h4Style() -> some View {
        self.font(.system(size: 14, weight: .regular))
            .foregroundColor(AppColor.foreground.opacity(0.8))
    }
    
    func h4MediumStyle() -> some View {
        self.font(.system(size: 14, weight: .medium))
            .foregroundColor(AppColor.foreground)
    }
} 