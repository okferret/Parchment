//
//  UINavigationBar+Extends.swift
//  Parchment
//
//  Created by okferret on 2026/6/3.
//

#if canImport(UIKit)

import UIKit

extension UINavigationBar: Compatible {}
extension CompatibleWrapper where Base: UINavigationBar {
    
    /// Reset background and shadow properties to their defaults.
    internal func configureWithDefaultBackground() {
        let barAppearance: UINavigationBarAppearance = .init()
        barAppearance.configureWithDefaultBackground()
        base.standardAppearance = barAppearance//.copy()
        base.compactAppearance = barAppearance.copy()
        base.scrollEdgeAppearance = barAppearance.copy()
        if #available(iOS 15.0, *) {
            base.compactScrollEdgeAppearance = barAppearance.copy()
        }
    }
    
    /// Reset background and shadow properties to display theme-appropriate opaque colors.
    internal func configureWithOpaqueBackground() {
        let barAppearance: UINavigationBarAppearance = .init()
        barAppearance.configureWithOpaqueBackground()
        base.standardAppearance = barAppearance//.copy()
        base.compactAppearance = barAppearance.copy()
        base.scrollEdgeAppearance = barAppearance.copy()
        if #available(iOS 15.0, *) {
            base.compactScrollEdgeAppearance = barAppearance.copy()
        }
    }
    
    /// Reset background and shadow properties to be transparent.
    internal func configureWithTransparentBackground() {
        let barAppearance: UINavigationBarAppearance = .init()
        barAppearance.configureWithTransparentBackground()
        base.standardAppearance = barAppearance//.copy()
        base.compactAppearance = barAppearance.copy()
        base.scrollEdgeAppearance = barAppearance.copy()
        if #available(iOS 15.0, *) {
            base.compactScrollEdgeAppearance = barAppearance.copy()
        }
    }
    
    /// A specific blur effect to use for the bar background. This effect is composited first when constructing the bar's background.
    /// - Parameter backgroundEffect: Optional<UIBlurEffect>
    internal func backgroundEffect(_ backgroundEffect: Optional<UIBlurEffect>) {
        let standardAppearance = base.standardAppearance.copy()
        standardAppearance.backgroundEffect = backgroundEffect
        base.standardAppearance = standardAppearance
        
        let compactAppearance = base.compactAppearance?.copy()
        compactAppearance?.backgroundEffect = backgroundEffect
        base.compactAppearance = compactAppearance
        
        let scrollEdgeAppearance = base.scrollEdgeAppearance?.copy()
        scrollEdgeAppearance?.backgroundEffect = backgroundEffect
        base.scrollEdgeAppearance = scrollEdgeAppearance
        
        if #available(iOS 15.0, *) {
            let compactScrollEdgeAppearance = base.compactScrollEdgeAppearance?.copy()
            compactScrollEdgeAppearance?.backgroundEffect = backgroundEffect
            base.compactScrollEdgeAppearance = compactScrollEdgeAppearance
        }
    }
    
    /// A color to use for the bar background. This color is composited over backgroundEffects.
    /// - Parameter backgroundColor: UIColor
    internal func backgroundColor(_ backgroundColor: Optional<UIColor>) {
        let standardAppearance = base.standardAppearance.copy()
        standardAppearance.backgroundColor = backgroundColor
        base.standardAppearance = standardAppearance
        
        let compactAppearance = base.compactAppearance?.copy()
        compactAppearance?.backgroundColor = backgroundColor
        base.compactAppearance = compactAppearance
        
        let scrollEdgeAppearance = base.scrollEdgeAppearance?.copy()
        scrollEdgeAppearance?.backgroundColor = backgroundColor
        base.scrollEdgeAppearance = scrollEdgeAppearance
        
        if #available(iOS 15.0, *) {
            let compactScrollEdgeAppearance = base.compactScrollEdgeAppearance?.copy()
            compactScrollEdgeAppearance?.backgroundColor = backgroundColor
            base.compactScrollEdgeAppearance = compactScrollEdgeAppearance
        }
    }
    
    /// An image to use for the bar background. This image is composited over the backgroundColor, and resized per the backgroundImageContentMode.
    /// - Parameter backgroundImage: UIImage
    internal func backgroundImage(_ backgroundImage: Optional<UIImage>) {
        let standardAppearance = base.standardAppearance.copy()
        standardAppearance.backgroundImage = backgroundImage
        base.standardAppearance = standardAppearance
        
        let compactAppearance = base.compactAppearance?.copy()
        compactAppearance?.backgroundImage = backgroundImage
        base.compactAppearance = compactAppearance
        
        let scrollEdgeAppearance = base.scrollEdgeAppearance?.copy()
        scrollEdgeAppearance?.backgroundImage = backgroundImage
        base.scrollEdgeAppearance = scrollEdgeAppearance
        
        if #available(iOS 15.0, *) {
            let compactScrollEdgeAppearance = base.compactScrollEdgeAppearance?.copy()
            compactScrollEdgeAppearance?.backgroundImage = backgroundImage
            base.compactScrollEdgeAppearance = compactScrollEdgeAppearance
        }
    }
    
    /// The content mode to use when rendering the backgroundImage. Defaults to UIViewContentModeScaleToFill.
    /// UIViewContentModeRedraw will be reinterpreted as UIViewContentModeScaleToFill.
    /// - Parameter backgroundImageContentMode: UIViewContentMode
    internal func backgroundImageContentMode(_ backgroundImageContentMode: UIView.ContentMode) {
        let standardAppearance = base.standardAppearance.copy()
        standardAppearance.backgroundImageContentMode = backgroundImageContentMode
        base.standardAppearance = standardAppearance
        
        let compactAppearance = base.compactAppearance?.copy()
        compactAppearance?.backgroundImageContentMode = backgroundImageContentMode
        base.compactAppearance = compactAppearance
        
        let scrollEdgeAppearance = base.scrollEdgeAppearance?.copy()
        scrollEdgeAppearance?.backgroundImageContentMode = backgroundImageContentMode
        base.scrollEdgeAppearance = scrollEdgeAppearance
        
        if #available(iOS 15.0, *) {
            let compactScrollEdgeAppearance = base.compactScrollEdgeAppearance?.copy()
            compactScrollEdgeAppearance?.backgroundImageContentMode = backgroundImageContentMode
            base.compactScrollEdgeAppearance = compactScrollEdgeAppearance
        }
    }
    
    /// A color to use for the shadow. Its specific behavior depends on the value of shadowImage.
    ///  If shadowImage is nil, then the shadowColor is used to color the bar's default shadow;
    ///  a nil or clearColor shadowColor will result in no shadow. If shadowImage is a template image, then the shadowColor is used to tint the image;
    ///  a nil or clearColor shadowColor will also result in no shadow.
    ///  If the shadowImage is not a template image, then it will be rendered regardless of the value of shadowColor.
    /// - Parameter shadowColor: Optional<UIColor>
    internal func shadowColor(_ shadowColor: Optional<UIColor>) {
        let standardAppearance = base.standardAppearance.copy()
        standardAppearance.shadowColor = shadowColor
        base.standardAppearance = standardAppearance
        
        let compactAppearance = base.compactAppearance?.copy()
        compactAppearance?.shadowColor = shadowColor
        base.compactAppearance = compactAppearance
        
        let scrollEdgeAppearance = base.scrollEdgeAppearance?.copy()
        scrollEdgeAppearance?.shadowColor = shadowColor
        base.scrollEdgeAppearance = scrollEdgeAppearance
        
        if #available(iOS 15.0, *) {
            let compactScrollEdgeAppearance = base.compactScrollEdgeAppearance?.copy()
            compactScrollEdgeAppearance?.shadowColor = shadowColor
            base.compactScrollEdgeAppearance = compactScrollEdgeAppearance
        }
    }
    
    /// Use an image for the shadow. See shadowColor for how they interact.
    /// - Parameter shadowImage: Optional<UIImage>
    internal func shadowImage(_ shadowImage: Optional<UIImage>) {
        let standardAppearance = base.standardAppearance.copy()
        standardAppearance.shadowImage = shadowImage
        base.standardAppearance = standardAppearance
        
        let compactAppearance = base.compactAppearance?.copy()
        compactAppearance?.shadowImage = shadowImage
        base.compactAppearance = compactAppearance
        
        let scrollEdgeAppearance = base.scrollEdgeAppearance?.copy()
        scrollEdgeAppearance?.shadowImage = shadowImage
        base.scrollEdgeAppearance = scrollEdgeAppearance
        
        if #available(iOS 15.0, *) {
            let compactScrollEdgeAppearance = base.compactScrollEdgeAppearance?.copy()
            compactScrollEdgeAppearance?.shadowImage = shadowImage
            base.compactScrollEdgeAppearance = compactScrollEdgeAppearance
        }
    }
    
    /// Inline Title text attributes. If the font or color are unspecified, appropriate defaults are supplied.
    /// - Parameter titleTextAttributes: [NSAttributedString.Key : Any]
    internal func titleTextAttributes(_ titleTextAttributes: [NSAttributedString.Key : Any]) {
        let standardAppearance = base.standardAppearance.copy()
        standardAppearance.titleTextAttributes = titleTextAttributes
        base.standardAppearance = standardAppearance
        
        let compactAppearance = base.compactAppearance?.copy()
        compactAppearance?.titleTextAttributes = titleTextAttributes
        base.compactAppearance = compactAppearance
        
        let scrollEdgeAppearance = base.scrollEdgeAppearance?.copy()
        scrollEdgeAppearance?.titleTextAttributes = titleTextAttributes
        base.scrollEdgeAppearance = scrollEdgeAppearance
        
        if #available(iOS 15.0, *) {
            let compactScrollEdgeAppearance = base.compactScrollEdgeAppearance?.copy()
            compactScrollEdgeAppearance?.titleTextAttributes = titleTextAttributes
            base.compactScrollEdgeAppearance = compactScrollEdgeAppearance
        }
    }
    
    /// An additional adjustment to the inline title's position.
    /// - Parameter titlePositionAdjustment: UIOffset
    internal func titlePositionAdjustment(_ titlePositionAdjustment: UIOffset) {
        let standardAppearance = base.standardAppearance.copy()
        standardAppearance.titlePositionAdjustment = titlePositionAdjustment
        base.standardAppearance = standardAppearance
        
        let compactAppearance = base.compactAppearance?.copy()
        compactAppearance?.titlePositionAdjustment = titlePositionAdjustment
        base.compactAppearance = compactAppearance
        
        let scrollEdgeAppearance = base.scrollEdgeAppearance?.copy()
        scrollEdgeAppearance?.titlePositionAdjustment = titlePositionAdjustment
        base.scrollEdgeAppearance = scrollEdgeAppearance
        
        if #available(iOS 15.0, *) {
            let compactScrollEdgeAppearance = base.compactScrollEdgeAppearance?.copy()
            compactScrollEdgeAppearance?.titlePositionAdjustment = titlePositionAdjustment
            base.compactScrollEdgeAppearance = compactScrollEdgeAppearance
        }
    }
    
    /// The default text attributes to apply to the subtitle rendered in the navigation bar.
    /// - Parameter subtitleTextAttributes: [NSAttributedString.Key : Any]
    @available(iOS 26.0, *)
    internal func subtitleTextAttributes(_ subtitleTextAttributes: [NSAttributedString.Key : Any]) {
        let standardAppearance = base.standardAppearance.copy()
        standardAppearance.subtitleTextAttributes = subtitleTextAttributes
        base.standardAppearance = standardAppearance
        
        let compactAppearance = base.compactAppearance?.copy()
        compactAppearance?.subtitleTextAttributes = subtitleTextAttributes
        base.compactAppearance = compactAppearance
        
        let scrollEdgeAppearance = base.scrollEdgeAppearance?.copy()
        scrollEdgeAppearance?.subtitleTextAttributes = subtitleTextAttributes
        base.scrollEdgeAppearance = scrollEdgeAppearance
        let compactScrollEdgeAppearance = base.compactScrollEdgeAppearance?.copy()
        compactScrollEdgeAppearance?.subtitleTextAttributes = subtitleTextAttributes
        base.compactScrollEdgeAppearance = compactScrollEdgeAppearance
    }
    
    /// Large Title text attributes. If the font or color are unspecified, appropriate defaults are supplied.
    /// - Parameter largeTitleTextAttributes: [NSAttributedString.Key : Any]
    internal func largeTitleTextAttributes(_ largeTitleTextAttributes: [NSAttributedString.Key : Any]) {
        let standardAppearance = base.standardAppearance.copy()
        standardAppearance.largeTitleTextAttributes = largeTitleTextAttributes
        base.standardAppearance = standardAppearance
        
        let compactAppearance = base.compactAppearance?.copy()
        compactAppearance?.largeTitleTextAttributes = largeTitleTextAttributes
        base.compactAppearance = compactAppearance
        
        let scrollEdgeAppearance = base.scrollEdgeAppearance?.copy()
        scrollEdgeAppearance?.largeTitleTextAttributes = largeTitleTextAttributes
        base.scrollEdgeAppearance = scrollEdgeAppearance
        
        if #available(iOS 15.0, *) {
            let compactScrollEdgeAppearance = base.compactScrollEdgeAppearance?.copy()
            compactScrollEdgeAppearance?.largeTitleTextAttributes = largeTitleTextAttributes
            base.compactScrollEdgeAppearance = compactScrollEdgeAppearance
        }
    }
    
    /// The default text attributes to apply to the subtitle when it’s rendered under
    /// - Parameter largeSubtitleTextAttributes: [NSAttributedString.Key : Any]
    @available(iOS 26.0, *)
    internal func largeSubtitleTextAttributes(_ largeSubtitleTextAttributes: [NSAttributedString.Key : Any]) {
        let standardAppearance = base.standardAppearance.copy()
        standardAppearance.largeSubtitleTextAttributes = largeSubtitleTextAttributes
        base.standardAppearance = standardAppearance
        
        let compactAppearance = base.compactAppearance?.copy()
        compactAppearance?.largeSubtitleTextAttributes = largeSubtitleTextAttributes
        base.compactAppearance = compactAppearance
        
        let scrollEdgeAppearance = base.scrollEdgeAppearance?.copy()
        scrollEdgeAppearance?.largeSubtitleTextAttributes = largeSubtitleTextAttributes
        base.scrollEdgeAppearance = scrollEdgeAppearance
        let compactScrollEdgeAppearance = base.compactScrollEdgeAppearance?.copy()
        compactScrollEdgeAppearance?.largeSubtitleTextAttributes = largeSubtitleTextAttributes
        base.compactScrollEdgeAppearance = compactScrollEdgeAppearance
    }
    
    /// The appearance for plain-style bar button items
    /// - Parameter buttonAppearance: UIBarButtonItemAppearance
    internal func buttonAppearance(_ buttonAppearance: UIBarButtonItemAppearance) {
        let standardAppearance = base.standardAppearance.copy()
        standardAppearance.buttonAppearance = buttonAppearance
        base.standardAppearance = standardAppearance
        
        let compactAppearance = base.compactAppearance?.copy()
        compactAppearance?.buttonAppearance = buttonAppearance
        base.compactAppearance = compactAppearance
        
        let scrollEdgeAppearance = base.scrollEdgeAppearance?.copy()
        scrollEdgeAppearance?.buttonAppearance = buttonAppearance
        base.scrollEdgeAppearance = scrollEdgeAppearance
        
        if #available(iOS 15.0, *) {
            let compactScrollEdgeAppearance = base.compactScrollEdgeAppearance?.copy()
            compactScrollEdgeAppearance?.buttonAppearance = buttonAppearance
            base.compactScrollEdgeAppearance = compactScrollEdgeAppearance
        }
    }
    
    /// The appearance attributes for Prominent buttons.
    ///  Use this property to configure the appearance of bar button items that use `UIBarButtonItemStyleProminent`.
    ///  If the navigation bar doesn't have any buttons using this style, this property has no effect.
    /// - Parameter prominentButtonAppearance: UIBarButtonItemAppearance
    internal func prominentButtonAppearance(_ prominentButtonAppearance: UIBarButtonItemAppearance) {
        let standardAppearance = base.standardAppearance.copy()
        standardAppearance.prominentButtonAppearance = prominentButtonAppearance
        base.standardAppearance = standardAppearance
        
        let compactAppearance = base.compactAppearance?.copy()
        compactAppearance?.prominentButtonAppearance = prominentButtonAppearance
        base.compactAppearance = compactAppearance
        
        let scrollEdgeAppearance = base.scrollEdgeAppearance?.copy()
        scrollEdgeAppearance?.prominentButtonAppearance = prominentButtonAppearance
        base.scrollEdgeAppearance = scrollEdgeAppearance
        
        if #available(iOS 15.0, *) {
            let compactScrollEdgeAppearance = base.compactScrollEdgeAppearance?.copy()
            compactScrollEdgeAppearance?.prominentButtonAppearance = prominentButtonAppearance
            base.compactScrollEdgeAppearance = compactScrollEdgeAppearance
        }
    }
    
    /// The appearance for back buttons. Defaults are drawn from buttonAppearance when appropriate.
    /// - Parameter backButtonAppearance: UIBarButtonItemAppearance
    internal func backButtonAppearance(_ backButtonAppearance: UIBarButtonItemAppearance) {
        let standardAppearance = base.standardAppearance.copy()
        standardAppearance.backButtonAppearance = backButtonAppearance
        base.standardAppearance = standardAppearance
        
        let compactAppearance = base.compactAppearance?.copy()
        compactAppearance?.backButtonAppearance = backButtonAppearance
        base.compactAppearance = compactAppearance
        
        let scrollEdgeAppearance = base.scrollEdgeAppearance?.copy()
        scrollEdgeAppearance?.backButtonAppearance = backButtonAppearance
        base.scrollEdgeAppearance = scrollEdgeAppearance
        
        if #available(iOS 15.0, *) {
            let compactScrollEdgeAppearance = base.compactScrollEdgeAppearance?.copy()
            compactScrollEdgeAppearance?.backButtonAppearance = backButtonAppearance
            base.compactScrollEdgeAppearance = compactScrollEdgeAppearance
        }
    }
    
    /// Set the backIndicatorImage & backIndicatorTransitionMaskImage images. If either image is nil, then both images will be reset to their default.
    internal func setBackIndicatorImage(_ backIndicatorImage: UIImage?, transitionMaskImage backIndicatorTransitionMaskImage: UIImage?) {
        let standardAppearance = base.standardAppearance.copy()
        standardAppearance.setBackIndicatorImage(backIndicatorImage, transitionMaskImage: backIndicatorTransitionMaskImage)
        base.standardAppearance = standardAppearance
        
        let compactAppearance = base.compactAppearance?.copy()
        compactAppearance?.setBackIndicatorImage(backIndicatorImage, transitionMaskImage: backIndicatorTransitionMaskImage)
        base.compactAppearance = compactAppearance
        
        let scrollEdgeAppearance = base.scrollEdgeAppearance?.copy()
        scrollEdgeAppearance?.setBackIndicatorImage(backIndicatorImage, transitionMaskImage: backIndicatorTransitionMaskImage)
        base.scrollEdgeAppearance = scrollEdgeAppearance
        
        if #available(iOS 15.0, *) {
            let compactScrollEdgeAppearance = base.compactScrollEdgeAppearance?.copy()
            compactScrollEdgeAppearance?.setBackIndicatorImage(backIndicatorImage, transitionMaskImage: backIndicatorTransitionMaskImage)
            base.compactScrollEdgeAppearance = compactScrollEdgeAppearance
        }
    }
    
    /// The appearance for done-style bar button items
    @available(iOS, introduced: 13.0, deprecated: 26.0)
    internal func doneButtonAppearance(_ doneButtonAppearance: UIBarButtonItemAppearance) {
        let standardAppearance = base.standardAppearance.copy()
        standardAppearance.doneButtonAppearance = doneButtonAppearance
        base.standardAppearance = standardAppearance
        
        let compactAppearance = base.compactAppearance?.copy()
        compactAppearance?.doneButtonAppearance = doneButtonAppearance
        base.compactAppearance = compactAppearance
        
        let scrollEdgeAppearance = base.scrollEdgeAppearance?.copy()
        scrollEdgeAppearance?.doneButtonAppearance = doneButtonAppearance
        base.scrollEdgeAppearance = scrollEdgeAppearance
        
        if #available(iOS 15.0, *) {
            let compactScrollEdgeAppearance = base.compactScrollEdgeAppearance?.copy()
            compactScrollEdgeAppearance?.doneButtonAppearance = doneButtonAppearance
            base.compactScrollEdgeAppearance = compactScrollEdgeAppearance
        }
    }
    
}

#endif
