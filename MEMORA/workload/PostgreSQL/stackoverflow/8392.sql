
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId IN (1, 2) AND 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 YEAR'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId, u.DisplayName
),
TopContributors AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS PostCount,
        SUM(Score) AS TotalScore,
        AVG(Score) AS AverageScore
    FROM 
        RankedPosts
    WHERE 
        rn = 1
    GROUP BY 
        OwnerUserId
    ORDER BY 
        TotalScore DESC 
    LIMIT 10
)
SELECT 
    uc.DisplayName,
    tc.PostCount,
    tc.TotalScore,
    tc.AverageScore,
    (SELECT COUNT(*) FROM Badges b WHERE b.UserId = tc.OwnerUserId) AS BadgeCount 
FROM 
    TopContributors tc
JOIN 
    Users uc ON tc.OwnerUserId = uc.Id
ORDER BY 
    tc.TotalScore DESC;
