
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
),
UserScores AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,      
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,    
        COUNT(DISTINCT p.Id) * 10 AS ReputationScore    
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    GROUP BY 
        u.Id, u.DisplayName
),
MartialMasters AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
FinalRanking AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.UpVotes,
        us.DownVotes,
        us.ReputationScore + COALESCE(mm.BadgeCount, 0) AS TotalScore
    FROM 
        UserScores us
    LEFT JOIN 
        MartialMasters mm ON us.UserId = mm.UserId
)
SELECT 
    fr.UserId,
    fr.DisplayName,
    fr.TotalScore,
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.Score
FROM 
    FinalRanking fr
JOIN 
    RankedPosts rp ON fr.UserId = rp.OwnerUserId
WHERE 
    fr.TotalScore > 50  
ORDER BY 
    fr.TotalScore DESC, 
    rp.CreationDate DESC;
