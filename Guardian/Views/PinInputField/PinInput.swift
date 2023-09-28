//
//  PinInput.swift
//  Vault
//
//  Created by Ata Namvari on 2023-10-01.
//

import Foundation
import UIKit

class PinInput: UIControl {
    class DigitView: UIView {
        private(set) lazy var label: UILabel = {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.font = .boldSystemFont(ofSize: 48)
            label.adjustsFontSizeToFitWidth = true
            label.textAlignment = .center
            label.text = " "
            label.textColor = .blue
            return label
        }()

        override init(frame: CGRect) {
            super.init(frame: frame)

            addSubview(label)
            addConstraints([
                label.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0),
                label.leadingAnchor.constraint(equalTo: leadingAnchor),
                label.trailingAnchor.constraint(equalTo: trailingAnchor)
            ])
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    class SpacerView: UIView {
        override var intrinsicContentSize: CGSize {
            CGSize(width: 1, height: 2)
        }
    }

    private lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.spacing = 12
        view.distribution = .fillEqually
        return view
    }()

    private let digitViews: [DigitView]

    let length: Int

    enum State {
        case error
        case normal
    }

    var errorState: State = .normal {
        didSet {
            setNeedsLayout()
        }
    }

    var value = [Int]() {
        didSet {
            for (i, view) in digitViews.enumerated() {
                guard i < value.count else {
                    view.label.text = " "
                    continue
                }

                view.label.text = String(value[i])
            }


            // Fire events
            sendActions(for: .valueChanged)

            if value.count == length {
                sendActions(for: .primaryActionTriggered)
            }

            setNeedsLayout()
        }
    }

    var tint: UIColor = .systemBlue
    var unfocusedColor: UIColor = .gray.withAlphaComponent(0.5)

    init(length: Int = 6) {
        self.length = length

        var views = [DigitView]()
        for _ in 0..<length {
            let view = DigitView()
            view.layer.borderWidth = 2
            view.layer.borderColor = UIColor.lightGray.cgColor.copy(alpha: 0.5)
            view.layer.cornerRadius = 4
            views.append(view)
        }
        digitViews = views

        super.init(frame: .zero)

        for i in 0..<digitViews.count {
            stackView.addArrangedSubview(digitViews[i])

            if digitViews.count.isMultiple(of: 2) && i == (digitViews.count / 2) - 1 {
                stackView.setCustomSpacing(12 + 12, after: digitViews[i])
            }
        }

        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(becomeFirstResponder))
        addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var canBecomeFirstResponder: Bool {
        true
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: stackView.intrinsicContentSize.width, height: 77)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        for (index, view) in digitViews.enumerated() {
            let color: UIColor = (isFirstResponder && index <= value.count) ? tintColor : unfocusedColor
            view.layer.borderColor = color.cgColor
            view.label.textColor = tintColor
        }
    }

    @discardableResult
    override func becomeFirstResponder() -> Bool {
        let status = super.becomeFirstResponder()
        setNeedsLayout()
        return status
    }
}

extension PinInput: UITextInputTraits {
    var keyboardType: UIKeyboardType {
        get {
            .numberPad
        }
        set {
            // no op
        }
    }

    var textContentType: UITextContentType! {
        get {
            .oneTimeCode
        }
        set {
            // no op
        }
    }
}

extension PinInput: UIKeyInput {
    func insertText(_ text: String) {
        if text.count == 1 {
            guard let integer = Int(text), integer < 10 && integer >= 0, isEnabled else {
                return
            }

            if value.count < length {
                value.append(integer)
            } else {
                value = [integer]
            }
        } else {
            guard text.count == length else {
                return
            }

            let digits = text.compactMap({ Int(String($0)) })

            guard digits.count == length else {
                return
            }

            value = digits
        }
    }

    func deleteBackward() {
        if value.count > 0 && isEnabled {
            value.removeLast()
        }
    }

    var hasText: Bool {
        false
    }
}

extension PinInput: UITextInput {
    func text(in range: UITextRange) -> String? {
        nil
    }

    func replace(_ range: UITextRange, withText text: String) {

    }

    var selectedTextRange: UITextRange? {
        get {
            nil
        }
        set(selectedTextRange) {

        }
    }

    var markedTextRange: UITextRange? {
        nil
    }

    var markedTextStyle: [NSAttributedString.Key : Any]? {
        get {
            nil
        }
        set(markedTextStyle) {

        }
    }

    func setMarkedText(_ markedText: String?, selectedRange: NSRange) {

    }

    func unmarkText() {

    }

    var beginningOfDocument: UITextPosition {
        UITextPosition()
    }

    var endOfDocument: UITextPosition {
        UITextPosition()
    }

    func textRange(from fromPosition: UITextPosition, to toPosition: UITextPosition) -> UITextRange? {
        nil
    }

    func position(from position: UITextPosition, offset: Int) -> UITextPosition? {
        nil
    }

    func position(from position: UITextPosition, in direction: UITextLayoutDirection, offset: Int) -> UITextPosition? {
        nil
    }

    func compare(_ position: UITextPosition, to other: UITextPosition) -> ComparisonResult {
        .orderedSame
    }

    func offset(from: UITextPosition, to toPosition: UITextPosition) -> Int {
        0
    }

    var inputDelegate: UITextInputDelegate? {
        get {
            nil
        }
        set(inputDelegate) {

        }
    }

    var tokenizer: UITextInputTokenizer {
        UITextInputStringTokenizer(textInput: self)
    }

    func position(within range: UITextRange, farthestIn direction: UITextLayoutDirection) -> UITextPosition? {
        nil
    }

    func characterRange(byExtending position: UITextPosition, in direction: UITextLayoutDirection) -> UITextRange? {
        nil
    }

    func baseWritingDirection(for position: UITextPosition, in direction: UITextStorageDirection) -> NSWritingDirection {
        .leftToRight
    }

    func setBaseWritingDirection(_ writingDirection: NSWritingDirection, for range: UITextRange) {

    }

    func firstRect(for range: UITextRange) -> CGRect {
        .zero
    }

    func caretRect(for position: UITextPosition) -> CGRect {
        .zero
    }

    func selectionRects(for range: UITextRange) -> [UITextSelectionRect] {
        []
    }

    func closestPosition(to point: CGPoint) -> UITextPosition? {
        nil
    }

    func closestPosition(to point: CGPoint, within range: UITextRange) -> UITextPosition? {
        nil
    }

    func characterRange(at point: CGPoint) -> UITextRange? {
        nil
    }
}
