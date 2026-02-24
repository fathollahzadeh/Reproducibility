
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.AnswerCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(c.Text, '; ') AS Comments
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate AS HistoryCreationDate,
        CASE 
            WHEN ph.PostHistoryTypeId IN (10, 11) THEN 
                'Closed on ' || ph.CreationDate::text
            WHEN ph.PostHistoryTypeId IN (12, 13) THEN 
                'Deleted on ' || ph.CreationDate::text
            ELSE 
                'Edited on ' || ph.CreationDate::text
        END AS HistoryText
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= CURRENT_DATE - INTERVAL '6 months'
),
UserBadges AS (
    SELECT
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS AwardedBadges
    FROM 
        Badges b
    WHERE 
        b.Date >= CURRENT_DATE - INTERVAL '2 years'
    GROUP BY 
        b.UserId
)
SELECT 
    rp.PostId, 
    rp.Title, 
    rp.CreationDate, 
    u.DisplayName AS OwnerDisplayName, 
    COALESCE(pc.CommentCount, 0) AS TotalComments,
    COALESCE(pc.Comments, 'No Comments') AS Comments,
    COALESCE(pdh.HistoryText, 'No History') AS PostHistory,
    ub.BadgeCount,
    ub.AwardedBadges,
    CASE 
        WHEN rp.Score > 0 THEN 
            'Positive Score'
        WHEN rp.Score < 0 THEN 
            'Negative Score'
        ELSE 
            'Neutral'
    END AS ScoreDescription
FROM 
    RankedPosts rp
LEFT JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    PostComments pc ON rp.PostId = pc.PostId
LEFT JOIN 
    PostHistoryDetails pdh ON rp.PostId = pdh.PostId
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
WHERE 
    rp.rn = 1
  AND 
    (rp.AnswerCount > 0 OR u.Reputation > 1000)
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC
