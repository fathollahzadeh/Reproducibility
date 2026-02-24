
WITH PostScore AS (
    SELECT 
        p.Id AS PostId,
        p.Score,
        p.AnswerCount,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS TagCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    JOIN 
        PostScore ps ON ps.PostId = p.Id
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(p.Id) > 10
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        SUM(COALESCE(v.BountyAmount, 0)) > 100
)
SELECT 
    p.Title,
    p.Score,
    pt.TagName,
    u.DisplayName AS TopUser,
    ps.AnswerCount,
    ps.ViewCount,
    COALESCE(cp.CloseCount, 0) AS CloseCount
FROM 
    Posts p
LEFT JOIN 
    PostScore ps ON p.Id = ps.PostId
JOIN 
    PopularTags pt ON p.Tags LIKE CONCAT('%', pt.TagName, '%')
LEFT JOIN 
    ClosedPosts cp ON p.Id = cp.PostId
JOIN 
    TopUsers u ON u.TotalBounty = (SELECT MAX(TotalBounty) FROM TopUsers)
WHERE 
    ps.RankScore <= 10
ORDER BY 
    p.Score DESC, pt.TagName;
