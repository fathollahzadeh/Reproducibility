
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COALESCE(MAX(ph.CreationDate), CAST('1900-01-01' AS timestamp)) AS LastEdit,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY COALESCE(MAX(ph.CreationDate), CAST('1900-01-01' AS timestamp)) DESC) AS EditRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        PostHistory ph ON ph.PostId = p.Id
    GROUP BY 
        p.Id, p.Title
),
FilteredPosts AS (
    SELECT 
        ps.PostId, 
        ps.Title, 
        ps.CommentCount,
        ps.UpVotes,
        ps.DownVotes,
        ps.LastEdit,
        ps.EditRank
    FROM 
        PostStats ps
    WHERE 
        ps.CommentCount > 0 AND 
        ps.UpVotes > ps.DownVotes AND 
        ps.EditRank = 1
),
RankedPosts AS (
    SELECT 
        fp.*, 
        NTILE(5) OVER (ORDER BY fp.UpVotes DESC) AS VoteRank
    FROM 
        FilteredPosts fp
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    rp.LastEdit,
    rp.VoteRank,
    CASE 
        WHEN rp.UpVotes IS NULL THEN 'No votes'
        WHEN rp.UpVotes >= (SELECT AVG(UpVotes) FROM FilteredPosts) THEN 'Above Average'
        ELSE 'Below Average'
    END AS VoteStatus
FROM 
    RankedPosts rp
WHERE 
    NOT EXISTS (
        SELECT 1
        FROM Votes v 
        WHERE v.PostId = rp.PostId 
        AND v.UserId = (SELECT Id FROM Users WHERE DisplayName = 'SpecialUser') 
        AND v.VoteTypeId = 1 
    )
ORDER BY 
    rp.VoteRank, rp.LastEdit DESC
LIMIT 10;
