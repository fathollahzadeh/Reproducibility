WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
), TopContributors AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(*) AS PostCount,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(*) >= 10
), PostVoteCounts AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)
SELECT 
    rc.PostId,
    rc.Title,
    rc.CreationDate,
    rc.Score,
    pc.UpVotes,
    pc.DownVotes,
    tc.UserId,
    tc.DisplayName,
    tc.PostCount,
    tc.TotalScore
FROM 
    RankedPosts rc
LEFT JOIN 
    PostVoteCounts pc ON rc.PostId = pc.PostId
JOIN 
    TopContributors tc ON rc.PostId IN (
        SELECT 
            p.Id 
        FROM 
            Posts p
        WHERE 
            p.OwnerUserId = tc.UserId
    )
WHERE 
    rc.Rank <= 3
ORDER BY 
    tc.TotalScore DESC, rc.Score DESC;