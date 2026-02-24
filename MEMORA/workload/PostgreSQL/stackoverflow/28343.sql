
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        pt.Name AS PostType,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END), 0) AS UpvoteCount,
        COALESCE(SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END), 0) AS DownvoteCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY COUNT(c.Id) DESC, COALESCE(SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END), 0) DESC) AS Rank
    FROM
        Posts p
    LEFT JOIN
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
    GROUP BY
        p.Id, p.Title, p.Tags, pt.Name
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.PostType,
    rp.CommentCount,
    rp.UpvoteCount,
    rp.DownvoteCount,
    ARRAY_LENGTH(string_to_array(rp.Tags, '><'), 1) AS TagCount,
    CASE 
        WHEN rp.Rank <= 5 THEN 'Top Posts'
        ELSE 'Other Posts'
    END AS PostGroup
FROM
    RankedPosts rp
WHERE
    rp.Rank <= 10  
ORDER BY
    rp.PostType, rp.Rank;
