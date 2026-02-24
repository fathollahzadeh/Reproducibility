
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS Author,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY COUNT(v.Id) DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Tags,
    rp.Author,
    rp.VoteCount,
    (
        SELECT 
            STRING_AGG(CONCAT(c.UserDisplayName, ': ', c.Text), '; ')
        FROM 
            Comments c 
        WHERE 
            c.PostId = rp.PostId
    ) AS Comments,
    (
        SELECT 
            STRING_AGG(CONCAT(ph.CreationDate, ' - ', pht.Name, ': ', ph.Text), '; ')
        FROM 
            PostHistory ph
        JOIN 
            PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
        WHERE 
            ph.PostId = rp.PostId
    ) AS History
FROM 
    RankedPosts rp
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Rank, rp.VoteCount DESC;
