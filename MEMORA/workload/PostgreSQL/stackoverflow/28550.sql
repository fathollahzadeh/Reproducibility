
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Tags, p.CreationDate
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Tags,
        rp.CommentCount,
        rp.Upvotes,
        rp.Downvotes,
        rp.CreationDate
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5  
),
AggregatedData AS (
    SELECT 
        f.Tags,
        COUNT(f.PostId) AS TotalPosts,
        SUM(f.CommentCount) AS TotalComments,
        SUM(f.Upvotes) AS TotalUpvotes,
        SUM(f.Downvotes) AS TotalDownvotes
    FROM 
        FilteredPosts f
    GROUP BY 
        f.Tags
)
SELECT 
    a.Tags,
    a.TotalPosts,
    a.TotalComments,
    a.TotalUpvotes,
    a.TotalDownvotes,
    CASE 
        WHEN a.TotalPosts > 0 THEN (a.TotalUpvotes + 1.0) / (a.TotalPosts + 1.0)  
        ELSE 0
    END AS UpvoteRatio,
    CASE 
        WHEN a.TotalPosts > 0 THEN (a.TotalDownvotes + 1.0) / (a.TotalPosts + 1.0)  
        ELSE 0
    END AS DownvoteRatio
FROM 
    AggregatedData a
ORDER BY 
    a.TotalPosts DESC, a.TotalUpvotes DESC;
