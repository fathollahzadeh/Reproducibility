
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        ARRAY_AGG(DISTINCT t.TagName) AS TagsArray
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON t.WikiPostId = p.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.Score, p.AnswerCount
),
UserScores AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        COALESCE(SUM(p.Score), 0) AS TotalScore,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id AND v.PostId = p.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
RecentPostVotes AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId IN (2, 3)) AS UpDownVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId IN (4, 12)) AS SpamOffensiveVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '60 days'
    GROUP BY 
        p.Id
)

SELECT 
    us.UserId,
    us.DisplayName,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.TagsArray,
    us.TotalBounties,
    us.TotalScore,
    COALESCE(rp.Rank, 0) AS PostRank,
    COALESCE(pvv.UpDownVotes, 0) AS UpDownVotes,
    COALESCE(pvv.SpamOffensiveVotes, 0) AS SpamOffensiveVotes
FROM 
    UserScores us
JOIN 
    RankedPosts rp ON us.UserId = rp.OwnerUserId
LEFT JOIN 
    RecentPostVotes pvv ON rp.PostId = pvv.PostId
WHERE 
    us.BadgeCount > 2 
    AND (rp.Score > 10 OR rp.AnswerCount > 3)
ORDER BY 
    us.TotalScore DESC, rp.Score DESC
LIMIT 100;
