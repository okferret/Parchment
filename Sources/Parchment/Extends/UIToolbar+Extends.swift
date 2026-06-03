//
//  UIToolbar+Extends.swift
//  Parchment
//
//  Created by okferret on 2026/6/3.
//

#if canImport(UIKit)
import UIKit

extension UIToolbar: Compatible {}
extension CompatibleWrapper where Base: UIToolbar {
    
    
    /// Reset background and shadow properties to their defaults.
    internal func configureWithDefaultBackground() {
        let barAppearance: UIToolbarAppearance = .init()
        barAppearance.configureWithDefaultBackground()
        base.standardAppearance = barAppearance//.copy()
        base.compactAppearance = barAppearance.copy()
        if #available(iOS 15.0, *) {
            base.scrollEdgeAppearance = barAppearance.copy()
            base.compactScrollEdgeAppearance = barAppearance.copy()
        }
    }

    /// Reset background and shadow properties to display theme-appropriate opaque colors.
    internal func configureWithOpaqueBackground() {
        let barAppearance: UIToolbarAppearance = .init()
        barAppearance.configureWithOpaqueBackground()
        base.standardAppearance = barAppearance//.copy()
        base.compactAppearance = barAppearance.copy()
        if #available(iOS 15.0, *) {
            base.scrollEdgeAppearance = barAppearance.copy()
            base.compactScrollEdgeAppearance = barAppearance.copy()
        }
    }
    
    /// Reset background and shadow properties to be transparent.
    internal func configureWithTransparentBackground() {
        let barAppearance: UIToolbarAppearance = .init()
        barAppearance.configureWithTransparentBackground()
        base.standardAppearance = barAppearance//.copy()
        base.compactAppearance = barAppearance.copy()
        if #available(iOS 15.0, *) {
            base.scrollEdgeAppearance = barAppearance.copy()
            base.compactScrollEdgeAppearance = barAppearance.copy()
        }
    }

    /// A specific blur effect to use for the bar background. This effect is composited first when constructing the bar's background.
    /// - Parameter backgroundEffect: Optional<UIBlurEffect>
    internal func backgroundEffect(_ backgroundEffect: Optional<UIBlurEffect>) {
        base.standardAppearance.backgroundEffect = backgroundEffect
        base.compactAppearance?.backgroundEffect = backgroundEffect
        if #available(iOS 15.0, *) {
            base.scrollEdgeAppearance?.backgroundEffect = backgroundEffect
            base.compactScrollEdgeAppearance?.backgroundEffect = backgroundEffect
        }
    }

    /// A color to use for the bar background. This color is composited over backgroundEffects.
    /// - Parameter backgroundColor: UIColor
    internal func backgroundColor(_ backgroundColor: Optional<UIColor>) {
        base.standardAppearance.backgroundColor = backgroundColor
        base.compactAppearance?.backgroundColor = backgroundColor
        if #available(iOS 15.0, *) {
            base.scrollEdgeAppearance?.backgroundColor = backgroundColor
            base.compactScrollEdgeAppearance?.backgroundColor = backgroundColor
        }
    }
 
    /// An image to use for the bar background. This image is composited over the backgroundColor, and resized per the backgroundImageContentMode.
    /// - Parameter backgroundImage: UIImage
    internal func backgroundImage(_ backgroundImage: Optional<UIImage>) {
        base.standardAppearance.backgroundImage = backgroundImage
        base.compactAppearance?.backgroundImage = backgroundImage
        if #available(iOS 15.0, *) {
            base.scrollEdgeAppearance?.backgroundImage = backgroundImage
            base.compactScrollEdgeAppearance?.backgroundImage = backgroundImage
        }
    }

    /// The content mode to use when rendering the backgroundImage. Defaults to UIViewContentModeScaleToFill.
    /// UIViewContentModeRedraw will be reinterpreted as UIViewContentModeScaleToFill.
    /// - Parameter backgroundImageContentMode: UIViewContentMode
    internal func backgroundImageContentMode(_ backgroundImageContentMode: UIView.ContentMode) {
        base.standardAppearance.backgroundImageContentMode = backgroundImageContentMode
        base.compactAppearance?.backgroundImageContentMode = backgroundImageContentMode
        if #available(iOS 15.0, *) {
            base.scrollEdgeAppearance?.backgroundImageContentMode = backgroundImageContentMode
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
        if #available(iOS 15.0, *) {
            base.scrollEdgeAppearance?.shadowColor = shadowColor
            base.compactScrollEdgeAppearance?.shadowColor = shadowColor
        }
    }
    
    /// Use an image for the shadow. See shadowColor for how they interact.
    /// - Parameter shadowImage: Optional<UIImage>
    internal func shadowImage(_ shadowImage: Optional<UIImage>) {
        base.standardAppearance.shadowImage = shadowImage
        base.compactAppearance?.shadowImage = shadowImage
        if #available(iOS 15.0, *) {
            base.scrollEdgeAppearance?.shadowImage = shadowImage
            base.compactScrollEdgeAppearance?.shadowImage = shadowImage
        }
    }

    /// The appearance for plain-style bar button items
    /// - Parameter buttonAppearance: UIBarButtonItemAppearance
    internal func buttonAppearance(_ buttonAppearance: UIBarButtonItemAppearance) {
        base.standardAppearance.buttonAppearance = buttonAppearance
        base.compactAppearance?.buttonAppearance = buttonAppearance
        if #available(iOS 15.0, *) {
            base.scrollEdgeAppearance?.buttonAppearance = buttonAppearance
            base.compactScrollEdgeAppearance?.buttonAppearance = buttonAppearance
        }
    }

    /// The appearance attributes for Prominent buttons.
    /// Use this property to configure the appearance of bar button items that use `UIBarButtonItemStyleProminent`.
    /// If the navigation bar doesn't have any buttons using this style, this property has no effect.
    /// - Parameter prominentButtonAppearance: UIBarButtonItemAppearance
    @available(iOS 26.0, *)
    internal func prominentButtonAppearance(_ prominentButtonAppearance: UIBarButtonItemAppearance) {
        base.standardAppearance.prominentButtonAppearance = prominentButtonAppearance
        base.compactAppearance?.prominentButtonAppearance = prominentButtonAppearance
        base.scrollEdgeAppearance?.prominentButtonAppearance = prominentButtonAppearance
        base.compactScrollEdgeAppearance?.prominentButtonAppearance = prominentButtonAppearance
    }

    /// The appearance for done-style bar button items
    /// - Parameter doneButtonAppearance: UIBarButtonItemAppearance
    @available(iOS, introduced: 13.0, deprecated: 26.0)
    internal func doneButtonAppearance(_ doneButtonAppearance: UIBarButtonItemAppearance) {
        base.standardAppearance.doneButtonAppearance = doneButtonAppearance
        base.compactAppearance?.doneButtonAppearance = doneButtonAppearance
        if #available(iOS 15.0, *) {
            base.scrollEdgeAppearance?.doneButtonAppearance = doneButtonAppearance
            base.compactScrollEdgeAppearance?.doneButtonAppearance = doneButtonAppearance
        }
    }
}

#endif
