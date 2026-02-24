WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS Author,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId IN (1, 2) 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName, p.CreationDate
),

PopularPosts AS (
    SELECT 
        rp.*,
        (SELECT COUNT(*) FROM Votes WHERE PostId = rp.PostId AND VoteTypeId = 2) AS UpVotes 
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank = 1
        AND rp.CommentCount > 10 
)

SELECT 
    pp.PostId,
    pp.Title,
    pp.Body,
    pp.Tags,
    pp.Author,
    pp.CreationDate,
    pp.CommentCount,
    pp.VoteCount,
    pp.UpVotes,
    CASE 
        WHEN pp.UpVotes >= 50 THEN 'Hot' 
        WHEN pp.UpVotes >= 20 THEN 'Trending' 
        ELSE 'Regular' 
    END AS PopularityStatus
FROM 
    PopularPosts pp
ORDER BY 
    pp.UpVotes DESC, pp.CommentCount DESC;