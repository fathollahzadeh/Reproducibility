WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '6 months'
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.CreationDate, p.PostTypeId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerName,
        rp.CommentCount,
        rp.Upvotes,
        rp.Downvotes,
        rp.Rank
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
)
SELECT 
    tp.Title,
    tp.OwnerName,
    tp.CommentCount,
    tp.Upvotes,
    tp.Downvotes,
    CASE 
        WHEN tp.Upvotes - tp.Downvotes > 0 THEN 'Positive'
        WHEN tp.Upvotes - tp.Downvotes < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS Sentiment
FROM 
    TopPosts tp
ORDER BY 
    tp.Upvotes - tp.Downvotes DESC, tp.CommentCount DESC;