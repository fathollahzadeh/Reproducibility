
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        u.DisplayName AS OwnerDisplayName, 
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName, p.OwnerUserId
),
TopUserPosts AS (
    SELECT 
        rp.OwnerDisplayName, 
        SUM(rp.Score) AS TotalScore, 
        SUM(rp.ViewCount) AS TotalViews, 
        COUNT(rp.PostId) AS PostCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
    GROUP BY 
        rp.OwnerDisplayName
)
SELECT 
    tup.OwnerDisplayName, 
    tup.TotalScore, 
    tup.TotalViews, 
    tup.PostCount,
    ROW_NUMBER() OVER (ORDER BY tup.TotalScore DESC) AS UserRank
FROM 
    TopUserPosts tup
ORDER BY 
    tup.TotalScore DESC;
