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
        base.standardAppearance.backgroundEffect = backgroundEffect
        base.compactAppearance?.backgroundEffect = backgroundEffect
        base.scrollEdgeAppearance?.backgroundEffect = backgroundEffect
        if #available(iOS 15.0, *) {
            base.compactScrollEdgeAppearance?.backgroundEffect = backgroundEffect
        }
    }

    /// A color to use for the bar background. This color is composited over backgroundEffects.
    /// - Parameter backgroundColor: UIColor
    internal func backgroundColor(_ backgroundColor: Optional<UIColor>) {
        base.standardAppearance.backgroundColor = backgroundColor
        base.compactAppearance?.backgroundColor = backgroundColor
        base.scrollEdgeAppearance?.backgroundColor = backgroundColor
        if #available(iOS 15.0, *) {
            base.compactScrollEdgeAppearance?.backgroundColor = backgroundColor
        }
    }
 
    /// An image to use for the bar background. This image is composited over the backgroundColor, and resized per the backgroundImageContentMode.
    /// - Parameter backgroundImage: UIImage
    internal func backgroundImage(_ backgroundImage: Optional<UIImage>) {
        base.standardAppearance.backgroundImage = backgroundImage
        base.compactAppearance?.backgroundImage = backgroundImage
        base.scrollEdgeAppearance?.backgroundImage = backgroundImage
        if #available(iOS 15.0, *) {
            base.compactScrollEdgeAppearance?.backgroundImage = backgroundImage
        }
    }

    /// The content mode to use when rendering the backgroundImage. Defaults to UIViewContentModeScaleToFill.
    /// UIViewContentModeRedraw will be reinterpreted as UIViewContentModeScaleToFill.
    /// - Parameter backgroundImageContentMode: UIViewContentMode
    internal func backgroundImageContentMode(_ backgroundImageContentMode: UIView.ContentMode) {
        base.standardAppearance.backgroundImageContentMode = backgroundImageContentMode
        base.compactAppearance?.backgroundImageContentMode = backgroundImageContentMode
        base.scrollEdgeAppearance?.backgroundImageContentMode = backgroundImageContentMode
        if #available(iOS 15.0, *) {
            base.compactScrollEdgeAppearance?.backgroundImageContentMode = backgroundImageContentMode
        }
    }

    /// A color to use for the shadow. Its specific behavior depends on the value of shadowImage.
    ///  If shadowImage is nil, then the shadowColor is used to color the bar's default shadow;
    ///  a nil or clearColor shadowColor will result in no shadow. If shadowImage is a template image, then the shadowColor is used to tint the image;
    ///  a nil or clearColor shadowColor will also result in no shadow.
    ///  If the shadowImage is not a template image, then it will be rendered regardless of the value of shadowColor.
    /// - Parameter shadowColor: Optional<UIColor>
    internal func shadowColor(_ shadowColor: Optional<UIColor>) {
        base.standardAppearance.shadowColor = shadowColor
        base.compactAppearance?.shadowColor = shadowColor
        base.scrollEdgeAppearance?.shadowColor = shadowColor
        if #available(iOS 15.0, *) {
            base.compactScrollEdgeAppearance?.shadowColor = shadowColor
        }
    }
    
    /// Use an image for the shadow. See shadowColor for how they interact.
    /// - Parameter shadowImage: Optional<UIImage>
    internal func shadowImage(_ shadowImage: Optional<UIImage>) {
        base.standardAppearance.shadowImage = shadowImage
        base.compactAppearance?.shadowImage = shadowImage
        base.scrollEdgeAppearance?.shadowImage = shadowImage
        if #available(iOS 15.0, *) {
            base.compactScrollEdgeAppearance?.shadowImage = shadowImage
        }
    }
    
    /// Inline Title text attributes. If the font or color are unspecified, appropriate defaults are supplied.
    /// - Parameter titleTextAttributes: [NSAttributedString.Key : Any]
    internal func titleTextAttributes(_ titleTextAttributes: [NSAttributedString.Key : Any]) {
        base.standardAppearance.titleTextAttributes = titleTextAttributes
        base.compactAppearance?.titleTextAttributes = titleTextAttributes
        base.scrollEdgeAppearance?.titleTextAttributes = titleTextAttributes
        if #available(iOS 15.0, *) {
            base.compactScrollEdgeAppearance?.titleTextAttributes = titleTextAttributes
        }
    }
    
    /// An additional adjustment to the inline title's position.
    /// - Parameter titlePositionAdjustment: UIOffset
    internal func titlePositionAdjustment(_ titlePositionAdjustment: UIOffset) {
        base.standardAppearance.titlePositionAdjustment = titlePositionAdjustment
        base.compactAppearance?.titlePositionAdjustment = titlePositionAdjustment
        base.scrollEdgeAppearance?.titlePositionAdjustment = titlePositionAdjustment
        if #available(iOS 15.0, *) {
            base.compactScrollEdgeAppearance?.titlePositionAdjustment = titlePositionAdjustment
        }
    }
    
    /// The default text attributes to apply to the subtitle rendered in the navigation bar.
    /// - Parameter subtitleTextAttributes: [NSAttributedString.Key : Any]
    @available(iOS 26.0, *)
    internal func subtitleTextAttributes(_ subtitleTextAttributes: [NSAttributedString.Key : Any]) {
        if #available(iOS 26.0, *) {
            base.standardAppearance.subtitleTextAttributes = subtitleTextAttributes
            base.compactAppearance?.subtitleTextAttributes = subtitleTextAttributes
            base.scrollEdgeAppearance?.subtitleTextAttributes = subtitleTextAttributes
            base.compactScrollEdgeAppearance?.subtitleTextAttributes = subtitleTextAttributes
        }
    }
    
    /// Large Title text attributes. If the font or color are unspecified, appropriate defaults are supplied.
    /// - Parameter largeTitleTextAttributes: [NSAttributedString.Key : Any]
    internal func largeTitleTextAttributes(_ largeTitleTextAttributes: [NSAttributedString.Key : Any]) {
        base.standardAppearance.largeTitleTextAttributes = largeTitleTextAttributes
        base.compactAppearance?.largeTitleTextAttributes = largeTitleTextAttributes
        base.scrollEdgeAppearance?.largeTitleTextAttributes = largeTitleTextAttributes
        if #available(iOS 15.0, *) {
            base.compactScrollEdgeAppearance?.largeTitleTextAttributes = largeTitleTextAttributes
        }
    }
    
    /// The default text attributes to apply to the subtitle when it’s rendered under
    /// - Parameter largeSubtitleTextAttributes: [NSAttributedString.Key : Any]
    @available(iOS 26.0, *)
    internal func largeSubtitleTextAttributes(_ largeSubtitleTextAttributes: [NSAttributedString.Key : Any]) {
        if #available(iOS 26.0, *) {
            base.standardAppearance.largeSubtitleTextAttributes = largeSubtitleTextAttributes
            base.compactAppearance?.largeSubtitleTextAttributes = largeSubtitleTextAttributes
            base.scrollEdgeAppearance?.largeSubtitleTextAttributes = largeSubtitleTextAttributes
            base.compactScrollEdgeAppearance?.largeSubtitleTextAttributes = largeSubtitleTextAttributes
        }
    }
    
    /// The appearance for plain-style bar button items
    /// - Parameter buttonAppearance: UIBarButtonItemAppearance
    internal func buttonAppearance(_ buttonAppearance: UIBarButtonItemAppearance) {
        base.standardAppearance.buttonAppearance = buttonAppearance
        base.compactAppearance?.buttonAppearance = buttonAppearance
        base.scrollEdgeAppearance?.buttonAppearance = buttonAppearance
        if #available(iOS 15.0, *) {
            base.compactScrollEdgeAppearance?.buttonAppearance = buttonAppearance
        }
    }
    
    /// The appearance attributes for Prominent buttons.
    ///  Use this property to configure the appearance of bar button items that use `UIBarButtonItemStyleProminent`.
    ///  If the navigation bar doesn't have any buttons using this style, this property has no effect.
    /// - Parameter prominentButtonAppearance: UIBarButtonItemAppearance
    internal func prominentButtonAppearance(_ prominentButtonAppearance: UIBarButtonItemAppearance) {
        base.standardAppearance.prominentButtonAppearance = prominentButtonAppearance
        base.compactAppearance?.prominentButtonAppearance = prominentButtonAppearance
        base.scrollEdgeAppearance?.prominentButtonAppearance = prominentButtonAppearance
        if #available(iOS 15.0, *) {
            base.compactScrollEdgeAppearance?.prominentButtonAppearance = prominentButtonAppearance
        }
    }
    
    /// The appearance for back buttons. Defaults are drawn from buttonAppearance when appropriate.
    /// - Parameter backButtonAppearance: UIBarButtonItemAppearance
    internal func backButtonAppearance(_ backButtonAppearance: UIBarButtonItemAppearance) {
        base.standardAppearance.backButtonAppearance = backButtonAppearance
        base.compactAppearance?.backButtonAppearance = backButtonAppearance
        base.scrollEdgeAppearance?.backButtonAppearance = backButtonAppearance
        if #available(iOS 15.0, *) {
            base.compactScrollEdgeAppearance?.backButtonAppearance = backButtonAppearance
        }
    }
    
    /// Set the backIndicatorImage & backIndicatorTransitionMaskImage images. If either image is nil, then both images will be reset to their default.
    internal func setBackIndicatorImage(_ backIndicatorImage: UIImage?, transitionMaskImage backIndicatorTransitionMaskImage: UIImage?) {
        base.standardAppearance.setBackIndicatorImage(backIndicatorImage, transitionMaskImage: backIndicatorTransitionMaskImage)
        base.compactAppearance?.setBackIndicatorImage(backIndicatorImage, transitionMaskImage: backIndicatorTransitionMaskImage)
        base.scrollEdgeAppearance?.setBackIndicatorImage(backIndicatorImage, transitionMaskImage: backIndicatorTransitionMaskImage)
        if #available(iOS 15.0, *) {
            base.compactScrollEdgeAppearance?.setBackIndicatorImage(backIndicatorImage, transitionMaskImage: backIndicatorTransitionMaskImage)
        }
    }
    
    /// The appearance for done-style bar button items
    @available(iOS, introduced: 13.0, deprecated: 26.0)
    internal func doneButtonAppearance(_ doneButtonAppearance: UIBarButtonItemAppearance) {
        base.standardAppearance.doneButtonAppearance = doneButtonAppearance
        base.compactAppearance?.doneButtonAppearance = doneButtonAppearance
        base.scrollEdgeAppearance?.doneButtonAppearance = doneButtonAppearance
        if #available(iOS 15.0, *) {
            base.compactScrollEdgeAppearance?.doneButtonAppearance = doneButtonAppearance
        }
    }
    
}

#endif
