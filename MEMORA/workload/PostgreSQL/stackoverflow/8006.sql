
WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT p.Id) AS PostCount,
        ROW_NUMBER() OVER (ORDER BY SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        COALESCE(h.UserDisplayName, 'N/A') AS LastEditor,
        MAX(h.CreationDate) AS LastEditDate,
        pt.Name AS PostType
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory h ON p.Id = h.PostId
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate > CURRENT_TIMESTAMP - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.ViewCount, h.UserDisplayName, pt.Name
)
SELECT 
    ru.Rank,
    ru.DisplayName,
    ru.UpVotes,
    ru.DownVotes,
    ps.PostId,
    ps.Title,
    ps.ViewCount,
    ps.LastEditor,
    ps.LastEditDate,
    ps.PostType
FROM 
    RankedUsers ru
JOIN 
    PostStatistics ps ON ru.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = ps.PostId)
WHERE 
    ru.Rank <= 10
ORDER BY 
    ru.Rank, ps.ViewCount DESC;
