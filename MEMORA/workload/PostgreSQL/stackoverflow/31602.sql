
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.CreationDate DESC) AS RN,
        STRING_AGG(t.TagName, ', ') AS TagList
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        UNNEST(STRING_TO_ARRAY(p.Tags, '>><<')) AS t(TagName) ON TRUE
    WHERE 
        p.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY 
        p.Id, pt.Name, p.Title, p.CreationDate, p.ViewCount, p.Score
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.TagList
    FROM 
        RankedPosts rp
    WHERE 
        rp.RN = 1
),
UserVotes AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN vt.Name = 'UpMod' THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN vt.Name = 'DownMod' THEN 1 END) AS Downvotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
),
PostWithVotes AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.ViewCount,
        tp.Score,
        tp.TagList,
        COALESCE(uv.Upvotes, 0) AS Upvotes,
        COALESCE(uv.Downvotes, 0) AS Downvotes
    FROM 
        TopPosts tp
    LEFT JOIN 
        UserVotes uv ON tp.PostId = uv.PostId
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(bp.Upvotes, 0)) AS TotalUpvotes,
        SUM(COALESCE(bp.Downvotes, 0)) AS TotalDownvotes,
        COUNT(DISTINCT bp.PostId) AS PostsEngaged
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        UserVotes bp ON v.PostId = bp.PostId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ue.UserId,
    ue.DisplayName,
    ue.TotalUpvotes,
    ue.TotalDownvotes,
    ue.PostsEngaged,
    (ue.TotalUpvotes - ue.TotalDownvotes) AS NetEngagement,
    (SELECT COUNT(DISTINCT p.Id) 
        FROM Posts p 
        WHERE p.OwnerUserId = ue.UserId) AS TotalUserPosts
FROM 
    UserEngagement ue
WHERE 
    ue.TotalUpvotes > 10
ORDER BY 
    NetEngagement DESC
LIMIT 10;
