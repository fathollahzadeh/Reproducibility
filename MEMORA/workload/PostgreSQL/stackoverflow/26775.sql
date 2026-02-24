
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS Author,
        pt.Name AS PostType,
        COUNT(c.Id) AS CommentCount,
        AVG(vote.VoteTypeId) AS AverageVoteType,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes vote ON p.Id = vote.PostId
    LEFT JOIN 
        LATERAL (SELECT UNNEST(STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags)-2), '><')) AS TagName) AS tag_ids ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag_ids.TagName
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName, pt.Name
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        STRING_AGG(CONCAT(ph.CreationDate, ': ', pht.Name), '; ' ORDER BY ph.CreationDate) AS HistoryDetails,
        COUNT(*) AS EditCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
),
FinalPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.Author,
        rp.PostType,
        rp.CommentCount,
        rp.AverageVoteType,
        rp.Tags,
        pcd.HistoryDetails,
        pcd.EditCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistoryDetails pcd ON rp.PostId = pcd.PostId
)
SELECT 
    *,
    CASE 
        WHEN AverageVoteType >= 2 THEN 'Highly Voted'
        WHEN AverageVoteType BETWEEN 1 AND 2 THEN 'Moderately Voted'
        ELSE 'Low Voted'
    END AS VoteCategory
FROM 
    FinalPosts
ORDER BY 
    CreationDate DESC, CommentCount DESC;
