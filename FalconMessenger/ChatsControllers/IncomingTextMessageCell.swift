//
//  IncomingTextMessageCell.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/8/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import SafariServices


class IncomingTextMessageCell: BaseMessageCell {
  
  let textView: FalconTextView = {
    let textView = FalconTextView()
    textView.textColor = ThemeManager.currentTheme().incomingBubbleTextColor
    textView.textContainerInset = UIEdgeInsetsMake(textViewTopInset, incomingTextViewLeftInset, textViewBottomInset, incomingTextViewRightInset)
    
    return textView
  }()
  
  override func setupViews() {
    textView.delegate = self
    bubbleView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(handleLongTap(_:))) )
    contentView.addSubview(bubbleView)
    bubbleView.addSubview(textView)
    textView.addSubview(nameLabel)
    bubbleView.addSubview(timeLabel)
    
    bubbleView.frame.origin = BaseMessageCell.incomingBubbleOrigin
    timeLabel.backgroundColor = .clear
    timeLabel.textColor = UIColor.darkGray.withAlphaComponent(0.7)
    bubbleView.tintColor = ThemeManager.currentTheme().incomingBubbleTintColor
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    bubbleView.tintColor = ThemeManager.currentTheme().incomingBubbleTintColor
    textView.textColor = ThemeManager.currentTheme().incomingBubbleTextColor
  }

  func setupData(message: Message, isGroupChat: Bool) {
    self.message = message
    guard let messageText = message.text else { return }
    textView.text = messageText
    
    if isGroupChat {
      nameLabel.text = message.senderName ?? ""
      nameLabel.sizeToFit()
      bubbleView.frame.size = setupGroupBubbleViewSize(message: message)
      
      textView.textContainerInset.top = BaseMessageCell.groupIncomingTextViewTopInset
      textView.frame.size = CGSize(width: bubbleView.frame.width.rounded(), height: bubbleView.frame.height.rounded())
    } else {
      bubbleView.frame.size = setupDefaultBubbleViewSize(message: message)
      textView.frame.size = CGSize(width: bubbleView.frame.width, height: bubbleView.frame.height)
    }
    
    timeLabel.frame.origin = CGPoint(x: bubbleView.frame.width-timeLabel.frame.width, y: bubbleView.frame.height-timeLabel.frame.height-5)
 
    if let isCrooked = self.message?.isCrooked, isCrooked {
      bubbleView.image = ThemeManager.currentTheme().incomingBubble
    } else {
      bubbleView.image = ThemeManager.currentTheme().incomingPartialBubble
    }
  }
  
  fileprivate func setupDefaultBubbleViewSize(message: Message) -> CGSize {
    guard let portaritEstimate = message.estimatedFrameForText?.width, let landscapeEstimate = message.landscapeEstimatedFrameForText?.width else { return CGSize() }
    
    let portraitRect = setupFrameWithLabel(bubbleView.frame.origin.x, BaseMessageCell.bubbleViewMaxWidth,
                                           portaritEstimate, BaseMessageCell.incomingMessageHorisontalInsets, frame.size.height, 10).integral
    
    let landscapeRect = setupFrameWithLabel(bubbleView.frame.origin.x, BaseMessageCell.landscapeBubbleViewMaxWidth,
                                           landscapeEstimate, BaseMessageCell.incomingMessageHorisontalInsets, frame.size.height, 10).integral
    switch UIDevice.current.orientation {
    case .landscapeRight, .landscapeLeft:
      return landscapeRect.size
    default:
     return portraitRect.size
    }
  }
  
  fileprivate func setupGroupBubbleViewSize(message: Message) -> CGSize {
    guard let portaritWidth = message.estimatedFrameForText?.width else { return CGSize() }
    guard let landscapeWidth = message.landscapeEstimatedFrameForText?.width  else { return CGSize() }
    let portraitBubbleMaxW = BaseMessageCell.bubbleViewMaxWidth
    let portraitAuthorMaxW = BaseMessageCell.incomingGroupMessageAuthorNameLabelMaxWidth
    let landscapeBubbleMaxW = BaseMessageCell.landscapeBubbleViewMaxWidth
    let landscapeAuthoMaxW = BaseMessageCell.landscapeIncomingGroupMessageAuthorNameLabelMaxWidth
    
    switch UIDevice.current.orientation {
    case .landscapeRight, .landscapeLeft:
      return getGroupBubbleSize(messageWidth: landscapeWidth, bubbleMaxWidth: landscapeBubbleMaxW, authorMaxWidth: landscapeAuthoMaxW)
    default:
      return getGroupBubbleSize(messageWidth: portaritWidth, bubbleMaxWidth: portraitBubbleMaxW, authorMaxWidth: portraitAuthorMaxW)
    }
  }
  
  fileprivate func getGroupBubbleSize(messageWidth: CGFloat, bubbleMaxWidth: CGFloat, authorMaxWidth: CGFloat) -> CGSize {
    let horisontalInsets = BaseMessageCell.incomingMessageHorisontalInsets
    
    let rect = setupFrameWithLabel(bubbleView.frame.origin.x, bubbleMaxWidth, messageWidth, horisontalInsets, frame.size.height, 10).integral

    if nameLabel.frame.size.width >= rect.width - horisontalInsets {
      if nameLabel.frame.size.width >= authorMaxWidth {
        nameLabel.frame.size.width = authorMaxWidth
        return CGSize(width: bubbleMaxWidth, height: frame.size.height.rounded())
      }
      return CGSize(width: (nameLabel.frame.size.width + horisontalInsets).rounded(), height: frame.size.height.rounded())
    } else {
      return rect.size
    }
  }
}

extension IncomingTextMessageCell: UITextViewDelegate {
  func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
    guard interaction != .preview else { return false }
    guard ["http", "https"].contains(URL.scheme?.lowercased() ?? "")  else { return true }
    var svc = SFSafariViewController(url: URL as URL)
    
    if #available(iOS 11.0, *) {
      let configuration = SFSafariViewController.Configuration()
      configuration.entersReaderIfAvailable = true
      svc = SFSafariViewController(url: URL as URL, configuration: configuration)
    }
    
    svc.preferredControlTintColor = FalconPalette.defaultBlue
    svc.preferredBarTintColor = ThemeManager.currentTheme().generalBackgroundColor
    chatLogController?.present(svc, animated: true, completion: nil)
    
    return false
  }
}
