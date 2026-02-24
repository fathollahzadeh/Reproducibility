
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 YEAR'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
EligibleUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(rp.Score) AS TotalScore,
        RANK() OVER (ORDER BY SUM(rp.Score) DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    eu.UserId,
    eu.DisplayName,
    eu.Reputation,
    eu.BadgeCount,
    eu.TotalScore,
    eu.UserRank,
    COUNT(rp.PostId) AS PostCount
FROM 
    EligibleUsers eu
LEFT JOIN 
    RankedPosts rp ON eu.UserId = rp.OwnerUserId
WHERE 
    eu.UserRank <= 10
GROUP BY 
    eu.UserId, eu.DisplayName, eu.Reputation, eu.BadgeCount, eu.TotalScore, eu.UserRank
ORDER BY 
    eu.UserRank;
