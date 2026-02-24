
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= '2022-01-01'
),
UserVotingStats AS (
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(ph.Id) AS ChangeCount,
        MAX(ph.CreationDate) AS LastChange
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12, 13) 
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(DISTINCT p.Id) > 10
),
RecentPostsWithTags AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        pt.Name AS PostType,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Tags t ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS timestamp) - INTERVAL '30 days')
    GROUP BY 
        p.Id, p.Title, pt.Name
)
SELECT 
    r.PostId,
    r.Title,
    r.PostTypeId,
    r.Score,
    r.CreationDate,
    u.UserId,
    u.Upvotes,
    u.Downvotes,
    pcd.PostHistoryTypeId,
    pcd.ChangeCount,
    pcd.LastChange,
    rt.TagName AS PopularTag,
    rwt.Tags AS RecentPostTags
FROM 
    RankedPosts r
LEFT JOIN 
    UserVotingStats u ON r.PostId = u.UserId 
LEFT JOIN 
    PostHistoryDetails pcd ON r.PostId = pcd.PostId
LEFT JOIN 
    PopularTags rt ON r.PostId = ANY (SELECT DISTINCT ph.PostId FROM PostHistoryDetails ph WHERE ph.ChangeCount > 1)
LEFT JOIN 
    RecentPostsWithTags rwt ON r.PostId = rwt.PostId
WHERE 
    r.Rank <= 5  
    AND (u.Upvotes IS NOT NULL OR u.Downvotes IS NOT NULL)
ORDER BY 
    r.Score DESC,
    r.CreationDate DESC;
