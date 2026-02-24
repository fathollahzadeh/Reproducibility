WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON v.PostId = p.Id
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.Comment,
        ph.CreationDate,
        PHT.Name AS PostHistoryType,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes PHT ON ph.PostHistoryTypeId = PHT.Id
    WHERE 
        ph.Comment IS NOT NULL
)
SELECT 
    uvs.DisplayName,
    uvs.UpVotes,
    uvs.DownVotes,
    uvs.PostsCount,
    uvs.TotalViews,
    p.Title AS RecentPostTitle,
    ph.Comment AS RecentChangeComment,
    ph.CreationDate AS ChangeDate
FROM 
    UserVoteStats uvs
LEFT JOIN 
    Posts p ON uvs.UserId = p.OwnerUserId
LEFT JOIN 
    PostHistoryDetails ph ON p.Id = ph.PostId AND ph.HistoryRank = 1
WHERE 
    uvs.TotalViews > 100
ORDER BY 
    uvs.UpVotes DESC, uvs.DownVotes ASC, uvs.TotalViews DESC
LIMIT 10;
