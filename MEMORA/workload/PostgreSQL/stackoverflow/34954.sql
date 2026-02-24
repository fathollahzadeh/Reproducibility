
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
),
UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        um.UserId,
        um.DisplayName,
        um.Reputation,
        um.BadgeCount,
        um.UpVotes
    FROM 
        RankedPosts rp
    JOIN 
        UserMetrics um ON rp.OwnerUserId = um.UserId
    WHERE 
        rp.PostRank <= 5 
)

SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.DisplayName,
    pd.Reputation,
    pd.BadgeCount,
    pd.UpVotes,
    COALESCE(
        (SELECT COUNT(*) 
         FROM Comments c 
         WHERE c.PostId = pd.PostId), 0) AS CommentCount,
    COALESCE(
        (SELECT COUNT(*) 
         FROM Posts p 
         WHERE p.ParentId = pd.PostId), 0) AS AnswerCount
FROM 
    PostDetails pd
ORDER BY 
    pd.Score DESC, 
    pd.CreationDate DESC;
