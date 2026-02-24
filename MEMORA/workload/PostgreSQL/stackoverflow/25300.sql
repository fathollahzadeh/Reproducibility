
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS UniqueVoters,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
        AND p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate
),
PopularPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        Tags,
        CreationDate,
        CommentCount,
        UniqueVoters,
        RANK() OVER (ORDER BY UniqueVoters DESC, CommentCount DESC) AS PopularityRank
    FROM 
        RankedPosts
    WHERE 
        rn = 1
)
SELECT 
    pp.PostId,
    pp.Title,
    pp.Body,
    pp.Tags,
    pp.CreationDate,
    pp.CommentCount,
    pp.UniqueVoters,
    pht.Name AS PostHistoryType,
    STRING_AGG(h.Text, '; ') AS HistoryComments
FROM 
    PopularPosts pp
LEFT JOIN 
    PostHistory h ON pp.PostId = h.PostId
LEFT JOIN 
    PostHistoryTypes pht ON h.PostHistoryTypeId = pht.Id
WHERE 
    pp.PopularityRank <= 10 
GROUP BY 
    pp.PostId, pp.Title, pp.Body, pp.Tags, pp.CreationDate, pp.CommentCount, pp.UniqueVoters, pht.Name
ORDER BY 
    pp.UniqueVoters DESC, pp.CommentCount DESC;
