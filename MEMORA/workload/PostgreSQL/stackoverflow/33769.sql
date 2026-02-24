
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotesCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotesCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
BadgedUsers AS (
    SELECT 
        b.UserId, 
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Date) AS LastBadgeDate
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
QnAStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        us.DisplayName AS Owner,
        us.Reputation,
        s.UpVotesCount,
        s.DownVotesCount,
        bu.BadgeCount,
        rp.ViewCount,
        rp.CreationDate,
        rp.Score,
        rp.Tags,
        rp.Rank
    FROM 
        RankedPosts rp
    JOIN 
        UserStatistics us ON rp.OwnerUserId = us.UserId
    LEFT JOIN 
        BadgedUsers bu ON bu.UserId = us.UserId
    LEFT JOIN 
        UserStatistics s ON s.UserId = rp.OwnerUserId
)
SELECT 
    qs.PostId,
    qs.Title,
    qs.Owner,
    qs.Reputation,
    COALESCE(qs.BadgeCount, 0) AS BadgeCount,
    qs.UpVotesCount,
    qs.DownVotesCount,
    qs.ViewCount,
    qs.CreationDate,
    LEAD(qs.Title) OVER (ORDER BY qs.CreationDate DESC) AS NextPostTitle,
    DENSE_RANK() OVER (ORDER BY qs.Score DESC) AS ScoreRank
FROM 
    QnAStats qs
WHERE 
    qs.Rank = 1
ORDER BY 
    qs.Score DESC, 
    qs.CreationDate DESC;
