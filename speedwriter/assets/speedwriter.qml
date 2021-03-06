/* Copyright (c) 2012 BlackBerry Limited.
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 * http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import bb.cascades 1.2
import com.speedwriter 1.0

Page {
    property variant appScene: Application.scene
    
    // Need this to prevent the layout to change when the virtual keyboard is shown.
    resizeBehavior: PageResizeBehavior.None

    Container {
        layout: DockLayout {
        }

        // background image
        ImageView {
            id: backgroundImage
            imageSource: "asset:///images/background.png"
        }

        // Stacklayout holding gauge, text and input controls.
        // When in landscape mode, the layout orientation will change
        Container {
            id: stackContainer

            layout: StackLayout {
                //Changes to "RightToLeft when in landscape
                orientation: LayoutOrientation.TopToBottom
            }

            // GaugeContainer is placeholder for the custom control speedGauge
            Container {
                id: gaugeContainer
                topPadding: 20
                bottomPadding: 20
                horizontalAlignment: HorizontalAlignment.Fill

                layoutProperties: StackLayoutProperties {
                    spaceQuota: -1
                }

                SpeedGauge {
                    id: speedGauge
                    horizontalAlignment: HorizontalAlignment.Center
                }
            }

            // The Container with the speed text and the text input control.
            Container {
                id: textContainer

                Container {
                    id: speedTextContainer
                    maxHeight: 165
                    preferredWidth: 768
                    horizontalAlignment: HorizontalAlignment.Center

                    layout: DockLayout {
                    }

                    // Text background image.
                    ImageView {
                        id: bgImage
                        imageSource: "asset:///images/border_image_text_field_source.png.amd"
                        preferredWidth: 728
                        preferredHeight: speedTextContainer.maxHeight
                        horizontalAlignment: HorizontalAlignment.Center
                    }

                    // The speed text is put inside a ScrollView so that the entire text is
                    // layouted even as the translationY would move it outside. If it where to
                    // be put inside a Container instead the text would be cut.
                    ScrollView {
                        horizontalAlignment: HorizontalAlignment.Center
                        // Since the nine-sliced image has transparent boarders we have to adjust the position and size of the scrollview.
                        preferredHeight: speedTextContainer.maxHeight - 12
                        translationY: 6

                        // Need to add a scrollmode to prevent touch interaction with the scrollview control. Will just show the text.
                        scrollViewProperties {
                            scrollMode: ScrollMode.None
                        }

                        Label {
                            id: speedTextLabel
                            property int lineOffset: 0
                            multiline: true
                            preferredWidth: 688

                            // The position of the Label is changed as new lines are entered
                            // resulting in a line feed animation of this Label.
                            translationY: - wordChecker.line * lineOffset

                            textStyle {
                                fontSize: FontSize.PointValue
                                fontSizeValue: 10
                            }

                            attachedObjects: [
                                // In order to get the height of on line of text we use a layout update handler
                                // it measures the empty label to get the height of one line.
                                LayoutUpdateHandler {
                                    onLayoutFrameChanged: {
                                        if (speedTextLabel.lineOffset === 0) {
                                            speedTextLabel.lineOffset = layoutFrame.height
                                            
                                            // Once measured set the initial text.
                                            speedTextLabel.text = "<html><span style='color:#e0e0e0;'>" + wordChecker.remainingText + "</span></html>"
                                        }
                                    }
                                }
                            ]
                        }
                    }
                } // speedTextContainer

                // A multi-line text field used for text input
                TextField {
                    id: textInput
                    topPadding: 30
                    preferredWidth: bgImage.preferredWidth - 10
                    preferredHeight: 99
                    hintText: "Type here to see how fast you are."
                    textStyle {
                        fontSize: FontSize.PointValue
                        fontSizeValue: 10
                    }
                    input.flags: TextInputFlag.AutoCapitalizationOff | TextInputFlag.AutoCorrectionOff | TextInputFlag.PredictionOff | TextInputFlag.SpellCheckOff | TextInputFlag.WordSubstitutionOff
                    horizontalAlignment: HorizontalAlignment.Center
                    clearButtonVisible: false

                    // Custom validation is performed by the wordchecker object below
                    validator: Validator {
                        mode: ValidationMode.Custom
                        errorMessage: "You are doing something wrong"
                        state: ValidationState.Unknown

                        onValidate: {
                            if (wordChecker.valid) {
                                state = ValidationState.Valid;
                            } else {
                                state = ValidationState.Invalid;
                            }
                        }
                    }

                    onTextChanging: {
                        // Check if the entered text is correct or not by using the wordChecker object.
                        wordChecker.checkWord(text);
                        // Update the speed label.
                        if(wordChecker.remainingText.length>0){
                            speedTextLabel.text = "<html><span style='color:#1f1f1f;'>" + wordChecker.enteredLines + wordChecker.currentCorrectLine + "</span>" + "<span style='color:#e0e0e0;'>" + wordChecker.remainingText + "</span></html>"    
                        }
                        
                        if (! wordChecker.valid) {
                            // Always validate while the checker is in a invalid state to find out if we are still invalid.
                            validator.validate();
                        }
                    }
                } // textInput

            } // textContainer
        } // stackContainer
    } // rootContainer

    attachedObjects: [

        // Non-visual objects are added to QML as attached objects.
        // The WordChecker is the object that contains the logics for checking
        // the correctness of the entered text.
        WordChecker {
            id: wordChecker
            speedText: "Mary had a little lamb, its fleece \nwas white as snow. Sea shells, \nsea shells, by the sea shore. The \nflirtatious flamingo relentlessly \nargued with the aerodynamic \nalbatross. Admire the \nmiscellaneous velociraptors \nbasking in the sun. Egotistic \naardvarks enthusiastically \neating lollipops. Precisely, \npronounced the presidential \nparrot presiding over the \npurple pachyderms. \n"
            onLineChanged: {
                // When one line has been entered correctly the textinput is cleared
                // to make room for entering the next line.
                textInput.text = "";
                textInput.hintText = "";
            }

            onEnded: {
                // The game is over, set up a text for displaying the final result in the text label and text area.
                speedTextLabel.text = "Your speed was " + speedGauge.averageSpeed + " words/min.\nWell done!";

                // Position the resulting text in the middle of the window and clear the other texts.
                speedTextLabel.translationY = 0;
                textInput.text = "";
                textInput.enabled = false;
            }

            onNbrOfCharactersChanged: {
                // A new correct character(s) has been entered so the speed is updated.
                speedGauge.calculateSpeed(nbrOfCharacters);
            }

            onValidChanged: {
                // Run validation on the text field if the word checker valid state changes.
                textInput.validator.validate();
            }
        },

        // The orientation handler takes care of orientation change events. What we do here
        // is simply to change values for properties so that the app will look great in portrait
        // as well as in landscape orientation.
        OrientationHandler {
            id: handler
            onOrientationAboutToChange: {
                if (orientation == UIOrientation.Landscape) {
                    // Change the background image and the orientation of the StackLayout.
                    backgroundImage.imageSource = "asset:///images/landscape_background.png"
                    stackContainer.layout.orientation = LayoutOrientation.RightToLeft

                    textContainer.topPadding = 30
                    textInput.topPadding = 20
                    gaugeContainer.topPadding = 30
                    gaugeContainer.bottomPadding = 30
                    gaugeContainer.layoutProperties.spaceQuota = "1"

                    // The Speed gauge is scaled downed to fit in landscape mode.
                    speedGauge.scaleY = 0.725
                    speedGauge.scaleX = 0.725
                    speedGauge.translationY = -50
                } else {
                    // Change to portrait background image and arrange the Controls from top to bottom.
                    backgroundImage.imageSource = "asset:///images/background.png"
                    stackContainer.layout.orientation = LayoutOrientation.TopToBottom

                    textContainer.topPadding = 0
                    textInput.topPadding = 30
                    gaugeContainer.topPadding = 40
                    gaugeContainer.bottomPadding = 40
                    gaugeContainer.layoutProperties.spaceQuota = "-1"
                    
                    // Reset the scale of the speed gauge for portrait mode
                    speedGauge.scaleY = 1
                    speedGauge.scaleX = 1
                    speedGauge.translationY = 0
                }
            } // onOrientationAboutToChange
        } // OrientationHandler
    ] // attachedObjects


    // Enable support for portrait and landscape orientation.
    onCreationCompleted: {
        OrientationSupport.supportedDisplayOrientation = SupportedDisplayOrientation.All;
    }
    
    onAppSceneChanged: {
        // Focus cannot be requested until the Page actually been added to the scene,
        // so we wait until the scene has been set on the application.
        textInput.requestFocus();        
    }
    
}// Page
