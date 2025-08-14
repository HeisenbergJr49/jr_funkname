// ========================================
// ESX Radio Members UI - JavaScript
// Author: HeisenbergJr49
// ========================================

class RadioUI {
    constructor() {
        this.container = document.getElementById('radio-container');
        this.panel = document.getElementById('radio-panel');
        this.membersList = document.getElementById('members-list');
        this.memberTemplate = document.getElementById('member-template');
        this.channelName = document.getElementById('channel-name');
        this.memberCount = document.getElementById('member-count');
        this.channelInput = document.getElementById('channel-input');
        this.channelNumber = document.getElementById('channel-number');
        this.joinBtn = document.getElementById('join-btn');
        this.leaveBtn = document.getElementById('leave-btn');
        this.closeBtn = document.getElementById('close-btn');
        this.miniToggle = document.getElementById('mini-toggle');
        this.membersContainer = document.getElementById('members-container');
        
        this.isVisible = false;
        this.isMiniMode = false;
        this.currentChannelData = null;
        
        this.initializeEventListeners();
        this.loadSettings();
    }
    
    initializeEventListeners() {
        // Control buttons
        this.closeBtn.addEventListener('click', () => this.close());
        this.miniToggle.addEventListener('click', () => this.toggleMiniMode());
        
        // Channel management
        this.joinBtn.addEventListener('click', () => this.joinChannel());
        this.leaveBtn.addEventListener('click', () => this.leaveChannel());
        
        // Enter key for channel input
        this.channelNumber.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') {
                this.joinChannel();
            }
        });
        
        // ESC key to close
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape' && this.isVisible) {
                this.close();
            }
        });
        
        // Prevent context menu
        document.addEventListener('contextmenu', (e) => e.preventDefault());
    }
    
    loadSettings() {
        // Load theme
        const theme = 'dark'; // This would come from config
        this.setTheme(theme);
        
        // Load position
        const position = 'left'; // This would come from config
        this.setPosition(position);
    }
    
    setTheme(theme) {
        this.container.classList.remove('light', 'dark');
        this.container.classList.add(theme);
    }
    
    setPosition(position) {
        this.container.classList.remove('position-left', 'position-right');
        this.container.classList.add(`position-${position}`);
        
        if (position === 'right') {
            this.container.style.left = 'auto';
            this.container.style.right = '20px';
        }
    }
    
    setVisible(visible) {
        this.isVisible = visible;
        
        if (visible) {
            this.container.classList.remove('hidden');
            this.container.classList.add('visible');
            
            // Focus channel input if no channel data
            if (!this.currentChannelData || !this.currentChannelData.members || Object.keys(this.currentChannelData.members).length === 0) {
                setTimeout(() => {
                    this.channelNumber.focus();
                }, 100);
            }
        } else {
            this.container.classList.remove('visible');
            setTimeout(() => {
                this.container.classList.add('hidden');
            }, 300);
        }
    }
    
    toggleMiniMode() {
        this.isMiniMode = !this.isMiniMode;
        
        if (this.isMiniMode) {
            this.container.classList.add('mini');
        } else {
            this.container.classList.remove('mini');
        }
        
        // Save preference (would be sent to client)
        this.postMessage('toggleMiniMode', { miniMode: this.isMiniMode });
    }
    
    updateChannelData(data) {
        this.currentChannelData = data;
        
        if (!data || !data.members || Object.keys(data.members).length === 0) {
            // Show channel input
            this.showChannelInput();
            this.clearMembersList();
            this.channelName.textContent = 'Radio Channel';
            this.memberCount.textContent = '0 members';
        } else {
            // Show channel data
            this.hideChannelInput();
            this.updateChannelInfo(data);
            this.updateMembersList(data.members);
        }
    }
    
    updateChannelInfo(data) {
        this.channelName.textContent = data.name || `Channel ${data.id}`;
        this.memberCount.textContent = `${data.memberCount || 0} member${data.memberCount !== 1 ? 's' : ''}`;
    }
    
    updateMembersList(members) {
        this.clearMembersList();
        
        if (!members || Object.keys(members).length === 0) {
            this.membersList.classList.add('empty');
            return;
        }
        
        this.membersList.classList.remove('empty');
        
        // Sort members by name
        const sortedMembers = Object.values(members).sort((a, b) => 
            (a.name || '').localeCompare(b.name || '')
        );
        
        sortedMembers.forEach(member => {
            this.addMemberToList(member);
        });
    }
    
    addMemberToList(member) {
        const memberElement = this.createMemberElement(member);
        this.membersList.appendChild(memberElement);
        
        // Trigger animation
        setTimeout(() => {
            memberElement.style.opacity = '1';
            memberElement.style.transform = 'translateX(0)';
        }, 10);
    }
    
    createMemberElement(member) {
        const template = this.memberTemplate.content.cloneNode(true);
        const memberElement = template.querySelector('.member-item');
        
        memberElement.dataset.playerId = member.id;
        memberElement.querySelector('.member-name').textContent = member.name || 'Unknown';
        
        // Set member status
        const statusText = this.getMemberStatus(member);
        memberElement.querySelector('.member-status').textContent = statusText;
        
        // Set speaking state
        if (member.isSpeaking) {
            memberElement.classList.add('speaking');
        }
        
        return memberElement;
    }
    
    getMemberStatus(member) {
        if (member.joinTime) {
            const joinDate = new Date(member.joinTime * 1000);
            const now = new Date();
            const diff = Math.floor((now - joinDate) / 1000);
            
            if (diff < 60) {
                return 'Just joined';
            } else if (diff < 3600) {
                const minutes = Math.floor(diff / 60);
                return `${minutes} min ago`;
            } else {
                const hours = Math.floor(diff / 3600);
                return `${hours}h ago`;
            }
        }
        return 'Online';
    }
    
    updateMemberSpeaking(playerId, isSpeaking) {
        const memberElement = this.membersList.querySelector(`[data-player-id="${playerId}"]`);
        if (memberElement) {
            if (isSpeaking) {
                memberElement.classList.add('speaking');
            } else {
                memberElement.classList.remove('speaking');
            }
        }
    }
    
    clearMembersList() {
        this.membersList.innerHTML = '';
        this.membersList.classList.remove('empty');
    }
    
    showChannelInput() {
        this.channelInput.classList.remove('hidden');
        this.leaveBtn.classList.add('hidden');
    }
    
    hideChannelInput() {
        this.channelInput.classList.add('hidden');
        this.leaveBtn.classList.remove('hidden');
    }
    
    joinChannel() {
        const channelId = parseInt(this.channelNumber.value);
        
        if (!channelId || channelId < 1 || channelId > 999) {
            this.showError('Please enter a valid channel (1-999)');
            return;
        }
        
        this.postMessage('joinChannel', { channelId });
        this.channelNumber.value = '';
    }
    
    leaveChannel() {
        this.postMessage('leaveChannel', {});
    }
    
    close() {
        this.postMessage('closeUI', {});
    }
    
    showError(message) {
        // Simple error indication - could be enhanced with proper notifications
        this.channelNumber.style.borderColor = '#ef4444';
        this.channelNumber.focus();
        
        setTimeout(() => {
            this.channelNumber.style.borderColor = '';
        }, 2000);
    }
    
    postMessage(type, data = {}) {
        fetch(`https://${GetParentResourceName()}/${type}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(data)
        });
    }
}

// Message handlers
const radioUI = new RadioUI();

window.addEventListener('message', (event) => {
    const { type, data } = event.data;
    
    switch (type) {
        case 'setVisible':
            radioUI.setVisible(data.visible);
            break;
            
        case 'setMiniMode':
            if (data.miniMode !== radioUI.isMiniMode) {
                radioUI.toggleMiniMode();
            }
            break;
            
        case 'updateChannelData':
            radioUI.updateChannelData(data.data || data);
            break;
            
        case 'updateMemberSpeaking':
            radioUI.updateMemberSpeaking(data.playerId, data.isSpeaking);
            break;
            
        case 'setTheme':
            radioUI.setTheme(data.theme);
            break;
            
        case 'setPosition':
            radioUI.setPosition(data.position);
            break;
    }
});

// Utility function for resource name
function GetParentResourceName() {
    return window.location.hostname;
}

// Initialize UI
document.addEventListener('DOMContentLoaded', () => {
    console.log('[jr_funkname] UI initialized');
});

// Prevent drag and drop
document.addEventListener('dragstart', (e) => e.preventDefault());
document.addEventListener('drop', (e) => e.preventDefault());
document.addEventListener('dragover', (e) => e.preventDefault());