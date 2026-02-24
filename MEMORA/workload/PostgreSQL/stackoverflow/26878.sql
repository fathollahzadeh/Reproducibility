
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY STRING_AGG(t.TagName, ', ') ORDER BY p.CreationDate DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Tags t ON POSITION(t.TagName IN p.Tags) > 0
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName, p.CreationDate, p.Score
),
FilteredPosts AS (
    SELECT 
        PostId, Title, Body, OwnerDisplayName, CreationDate, Score, Tags
    FROM 
        RankedPosts
    WHERE 
        TagRank <= 3 
),
TopActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Users u
    JOIN 
        Posts p ON p.OwnerUserId = u.Id
    JOIN 
        Votes v ON v.UserId = u.Id
    WHERE 
        p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) > 5
)
SELECT 
    fp.Title,
    fp.Body,
    fp.OwnerDisplayName,
    fp.Tags,
    au.DisplayName AS ActiveUserName,
    au.PostCount,
    au.TotalBounty,
    fp.CreationDate
FROM 
    FilteredPosts fp
JOIN 
    TopActiveUsers au ON au.UserId = (SELECT u.Id FROM Users u WHERE u.DisplayName = fp.OwnerDisplayName LIMIT 1)
ORDER BY 
    fp.Score DESC, fp.CreationDate DESC;
