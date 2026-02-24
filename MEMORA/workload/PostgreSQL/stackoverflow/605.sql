
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserScores AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        COALESCE(SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END), 0) AS AcceptedAnswers
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostDetails AS (
    SELECT 
        rp.Id AS PostId,
        rp.Title,
        rp.CreationDate,
        us.DisplayName,
        rp.ViewCount,
        rp.Score,
        us.UpVoteCount,
        us.BadgeCount,
        us.AcceptedAnswers
    FROM 
        RankedPosts rp
    JOIN 
        UserScores us ON rp.OwnerUserId = us.UserId
    WHERE 
        rp.PostRank <= 5
)
SELECT 
    pd.Title,
    pd.CreationDate,
    pd.DisplayName,
    pd.ViewCount,
    pd.Score,
    pd.UpVoteCount,
    pd.BadgeCount,
    pd.AcceptedAnswers,
    COALESCE(ph.Comment, 'No history') AS LastEditComment,
    CASE 
        WHEN pd.Score > 10 THEN 'High Score'
        WHEN pd.Score BETWEEN 5 AND 10 THEN 'Medium Score'
        ELSE 'Low Score'
    END AS ScoreCategory
FROM 
    PostDetails pd
LEFT JOIN 
    PostHistory ph ON pd.PostId = ph.PostId 
                   AND ph.PostHistoryTypeId IN (4, 6, 24) 
                   AND ph.CreationDate = (
                       SELECT MAX(CreationDate)
                       FROM PostHistory
                       WHERE PostId = pd.PostId 
                       AND PostHistoryTypeId IN (4, 6, 24)
                   )
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC;
