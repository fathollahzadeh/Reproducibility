
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName, p.PostTypeId
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        OwnerDisplayName,
        TotalComments,
        TotalUpvotes,
        TotalDownvotes
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.OwnerDisplayName,
    tp.TotalComments,
    tp.TotalUpvotes,
    tp.TotalDownvotes,
    CASE 
        WHEN tp.TotalUpvotes > tp.TotalDownvotes THEN 'Positive'
        WHEN tp.TotalDownvotes > tp.TotalUpvotes THEN 'Negative'
        ELSE 'Neutral'
    END AS Sentiment,
    (
        SELECT 
            STRING_AGG(DISTINCT t.TagName, ', ') 
        FROM 
            Tags t
        WHERE 
            t.ExcerptPostId = tp.PostId
    ) AS Tags
FROM 
    TopPosts tp
ORDER BY 
    tp.TotalUpvotes DESC, tp.CreationDate ASC;
