
WITH PostVoteStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT v.Id) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate
), 
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        SUM(COALESCE(v.UpVotes, 0)) AS TotalUpVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
), 
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstEditDate,
        COUNT(*) AS EditCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        ph.PostId
)
SELECT 
    pvs.PostId,
    pvs.Title,
    pvs.CreationDate,
    pvs.UpVotes,
    pvs.DownVotes,
    pvs.TotalVotes,
    au.UserId,
    au.DisplayName,
    au.PostsCreated,
    au.TotalUpVotes,
    h.FirstEditDate,
    h.EditCount
FROM 
    PostVoteStats pvs
LEFT JOIN 
    ActiveUsers au ON pvs.PostId IN (SELECT DISTINCT ParentId FROM Posts WHERE PostTypeId = 2)
LEFT JOIN 
    PostHistoryDetails h ON pvs.PostId = h.PostId
WHERE 
    pvs.UpVotes > 5 OR au.PostsCreated > 10
ORDER BY 
    pvs.TotalVotes DESC,
    au.TotalUpVotes DESC
LIMIT 100;
