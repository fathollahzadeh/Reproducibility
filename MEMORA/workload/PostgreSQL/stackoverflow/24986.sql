
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank,
        COUNT(c.Id) AS CommentCountAggregate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '365 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount, p.AcceptedAnswerId
), UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        u.AccountId,
        COALESCE(SUM(b.Class), 0) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName, u.AccountId
), InterestingData AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        ur.DisplayName AS OwnerDisplayName,
        ur.Reputation AS OwnerReputation,
        ur.TotalBadges AS OwnerTotalBadges,
        CASE 
            WHEN rp.AnswerCount = 0 THEN 'No answers yet'
            WHEN rp.AnswerCount < 2 THEN 'Few answers'
            ELSE 'Popular post'
        END AS AnswerStatus,
        CASE 
            WHEN rp.ViewCount IS NULL THEN 'Unknown views' 
            WHEN rp.ViewCount > 1000 THEN 'High traffic'
            ELSE 'Low traffic'
        END AS ViewStatus
    FROM 
        RankedPosts rp
    JOIN 
        UserReputation ur ON ur.UserId = rp.PostId
    WHERE 
        rp.Score >= 5 AND rp.OwnerPostRank = 1
), BizarreLogic AS (
    SELECT 
        PostId,
        Title,
        OwnerDisplayName,
        OwnerReputation,
        AnswerStatus,
        ViewStatus,
        CASE 
            WHEN OwnerReputation IS NULL THEN 'Reputation not found'
            WHEN OwnerReputation < 1000 AND AnswerStatus = 'No answers yet' THEN 'Need more activity'
            ELSE 'Engaged user'
        END AS EngagementLevel
    FROM 
        InterestingData
)
SELECT 
    bl.PostId,
    bl.Title,
    bl.OwnerDisplayName,
    bl.OwnerReputation,
    bl.AnswerStatus,
    bl.ViewStatus,
    bl.EngagementLevel
FROM 
    BizarreLogic bl
WHERE 
    bl.EngagementLevel = 'Need more activity'
ORDER BY 
    bl.OwnerReputation DESC
LIMIT 10;
