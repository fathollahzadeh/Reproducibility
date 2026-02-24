
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN vote.UserId = u.Id AND vote.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN vote.UserId = u.Id AND vote.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes vote ON vote.UserId = u.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rs.UserId,
        rs.DisplayName,
        rs.Reputation,
        rp.Score,
        rp.ViewCount,
        (SELECT COUNT(c.Id) FROM Comments c WHERE c.PostId = rp.PostId) AS CommentCount,
        CASE 
            WHEN rp.AcceptedAnswerId IS NOT NULL THEN 1 
            ELSE 0 
        END AS HasAcceptedAnswer
    FROM 
        RankedPosts rp
    JOIN 
        UserStats rs ON rs.UserId = rp.OwnerUserId
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.DisplayName,
    pd.Reputation,
    pd.Score,
    pd.ViewCount,
    pd.CommentCount,
    pd.HasAcceptedAnswer,
    CASE 
        WHEN pd.Reputation >= 1000 THEN 'High Reputation'
        WHEN pd.Reputation < 1000 AND pd.Reputation >= 100 THEN 'Medium Reputation'
        ELSE 'Low Reputation'
    END AS ReputationCategory
FROM 
    PostDetails pd
WHERE 
    pd.CommentCount > 5
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC
LIMIT 10;
