
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
    AND 
        p.Score > 0 
),
TopPosts AS (
    SELECT
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.PostRank,
        rp.CommentCount,
        ROW_NUMBER() OVER (ORDER BY rp.Score DESC) AS OverallRank
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 5 
),
UserActivity AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        COUNT(v.Id) AS TotalVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostDetails AS (
    SELECT
        tp.Title,
        tp.CreationDate,
        tp.Score,
        tp.CommentCount,
        ua.DisplayName AS UserDisplayName,
        ua.TotalPosts,
        ua.TotalVotes,
        ua.TotalBounties,
        CASE 
            WHEN tp.CommentCount = 0 THEN 'No comments yet.'
            ELSE 'Comments present.'
        END AS CommentStatus
    FROM 
        TopPosts tp
    JOIN 
        Users u ON tp.Id = u.Id
    JOIN 
        UserActivity ua ON u.Id = ua.UserId
)
SELECT 
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.CommentCount,
    pd.UserDisplayName,
    pd.TotalPosts,
    pd.TotalVotes,
    pd.TotalBounties,
    pd.CommentStatus,
    CASE 
        WHEN pd.Score IS NULL THEN 'Post Score is NULL' 
        ELSE CAST(pd.Score AS VARCHAR)
    END AS ScoreStatus
FROM 
    PostDetails pd
WHERE 
    pd.TotalPosts > 0
ORDER BY 
    pd.CreationDate DESC;
