
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS Owner,
        COUNT(c.Id) AS CommentCount,
        AVG(v.VoteTypeId) AS AverageVoteType,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        LATERAL (
            SELECT 
                unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '>')) AS TagName
        ) AS t ON TRUE
    WHERE 
        p.CreationDate >= DATE '2024-10-01' - INTERVAL '1 year' 
    GROUP BY 
        p.Id, u.DisplayName, p.Body, p.CreationDate
),
FilteredPosts AS (
    SELECT 
        rp.*,
        RANK() OVER (ORDER BY rp.CommentCount DESC, rp.AverageVoteType DESC) AS Rank
    FROM 
        RankedPosts rp
    WHERE 
        LENGTH(rp.Tags) > 0 
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Owner,
    fp.CommentCount,
    fp.AverageVoteType,
    fp.Tags,
    CASE 
        WHEN fp.Rank <= 10 THEN 'Top 10'
        WHEN fp.Rank <= 20 THEN 'Top 20'
        ELSE 'Below Top 20'
    END AS RankCategory
FROM 
    FilteredPosts fp
ORDER BY 
    fp.Rank
LIMIT 50;
