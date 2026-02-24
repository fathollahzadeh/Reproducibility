WITH RECURSIVE UserActivities AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.LastAccessDate,
        u.Views,
        u.UpVotes,
        u.DownVotes,
        0 AS ActivityLevel
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000

    UNION ALL

    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.LastAccessDate,
        u.Views,
        u.UpVotes,
        u.DownVotes,
        ua.ActivityLevel + 1
    FROM 
        Users u
    INNER JOIN 
        UserActivities ua ON u.Id = ua.UserId
    WHERE 
        ua.ActivityLevel < 2  
),
PostVoteCounts AS (
    SELECT 
        p.OwnerUserId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.OwnerUserId
),
PostsWithHistory AS (
    SELECT 
        ph.UserId,
        COUNT(ph.Id) AS EditCount,
        STRING_AGG(DISTINCT pt.Name, ', ') AS PostTypes
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    GROUP BY 
        ph.UserId
),
FinalResults AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.Reputation,
        COALESCE(pvc.TotalVotes, 0) AS TotalVotes,
        COALESCE(pvc.UpVotes, 0) AS UpVotes,
        COALESCE(pvc.DownVotes, 0) AS DownVotes,
        COALESCE(pwh.EditCount, 0) AS EditCount,
        COALESCE(pwh.PostTypes, 'No edits') AS PostTypes,
        ua.ActivityLevel
    FROM 
        UserActivities ua
    LEFT JOIN 
        PostVoteCounts pvc ON ua.UserId = pvc.OwnerUserId
    LEFT JOIN 
        PostsWithHistory pwh ON ua.UserId = pwh.UserId
)
SELECT 
    f.UserId,
    f.DisplayName,
    f.Reputation,
    f.TotalVotes,
    f.UpVotes,
    f.DownVotes,
    f.EditCount,
    f.PostTypes,
    ROW_NUMBER() OVER (ORDER BY f.Reputation DESC) AS Rank
FROM 
    FinalResults f
WHERE 
    f.Reputation > 1000
ORDER BY 
    f.Reputation DESC, f.EditCount DESC;