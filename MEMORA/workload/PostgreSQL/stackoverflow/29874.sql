
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        u.DisplayName AS Author,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, u.DisplayName
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Author,
        rp.CommentCount,
        rp.Upvotes,
        rp.Downvotes,
        (rp.Upvotes - rp.Downvotes) AS NetVotes,
        CASE 
            WHEN rp.CommentCount > 10 THEN 'Highly Discussed' 
            WHEN rp.CommentCount BETWEEN 5 AND 10 THEN 'Moderately Discussed' 
            ELSE 'Less Discussed' 
        END AS DiscussionLevel
    FROM 
        RankedPosts rp
    WHERE 
        rp.RowNum = 1
)
SELECT 
    pd.Title,
    pd.Body,
    pd.Author,
    pd.CommentCount,
    pd.Upvotes,
    pd.Downvotes,
    pd.NetVotes,
    pd.DiscussionLevel,
    pt.Name AS PostTypeName
FROM 
    PostDetails pd
JOIN 
    PostTypes pt ON pd.PostId = pt.Id 
WHERE 
    pd.NetVotes > 0 
ORDER BY 
    pd.CommentCount DESC, pd.NetVotes DESC;
