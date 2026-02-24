WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
DetailedComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(c.Text, ' | ') AS CommentTexts
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
HighScorePosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        COALESCE(dc.CommentCount, 0) AS CommentCount,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount,
        ub.BadgeNames
    FROM 
        RankedPosts rp
    LEFT JOIN 
        DetailedComments dc ON rp.Id = dc.PostId
    LEFT JOIN 
        UserBadges ub ON rp.OwnerUserId = ub.UserId
    WHERE 
        rp.Score > 10 
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.UserDisplayName,
        ph.CreationDate,
        ph.Comment
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) 
)
SELECT 
    hsp.Id AS PostId,
    hsp.Title,
    hsp.CreationDate,
    hsp.Score,
    hsp.CommentCount,
    hsp.BadgeCount,
    hsp.BadgeNames,
    pht.UserDisplayName AS ActionUser,
    pht.CreationDate AS ActionDate,
    CASE 
        WHEN pht.PostHistoryTypeId = 10 THEN 'Closed'
        WHEN pht.PostHistoryTypeId = 11 THEN 'Reopened'
        WHEN pht.PostHistoryTypeId = 12 THEN 'Deleted'
        ELSE 'No Action'
    END AS ActionType
FROM 
    HighScorePosts hsp
LEFT JOIN 
    PostHistoryDetails pht ON hsp.Id = pht.PostId
ORDER BY 
    hsp.Score DESC, hsp.CommentCount DESC;