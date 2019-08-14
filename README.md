# Meadows_Swift

### Background
This is a Swift/iPad implementation of the MATLAB algorithm provided by the authors of 
https://www.frontiersin.org/articles/10.3389/fpsyg.2012.00245/full

---

### Input Parameters
- `Subject ID`:       Make sure this is unique and nonempty, otherwise it will write over existing data
- `Nondeterministic`: Default is off. You must type an integer in the adjacent box if you switch it on. If on, this option skips the usual way (in Mur et al.) of determining the stimuli for each iteration. Instead, it selects k random items from your chosen stimuli set, where k = your input number.
- `maxNumIterations`: Default is 60. Sets an upper bound on the number of arrangements to perform.
- `evidenceUtilityExponent`: Default is 10.
- `minRequiredEvidenceWeight`: Default is 0.5
- `maxSessionLength (min)`: Default is 60 min.
- `maxNumItemsPerTrial`: Default is 12. Reducing this number dramatically improves program runtime.
 ---
 
 ### Stimuli Type
 Default: Uses all the stimuli in the selected Group number.
 Custom: Shows a list of all the stimuli in the selected Group number. Then the experimenter/subject selects a subset of the stimuli with checkboxes.
 Slideshow: Shows all the stimuli in the selected Group number as a slide show. The subject then selects Yes/No based on their understanding of the stimulus.
 
 ---
 
 ### During Experiment
 Early Finish: this option will save the current experiment data as a .csv file on the iPad. It also opens an email dialog where the .csv file is loaded as an attachment.
