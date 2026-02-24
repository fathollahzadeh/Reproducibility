WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 6 THEN 1 ELSE 0 END), 0) AS CloseVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 9 THEN 1 ELSE 0 END), 0) AS BountyCloseVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.PostCount,
    ua.UpVotes,
    ua.DownVotes,
    ua.CloseVotes,
    ua.BountyCloseVotes
FROM 
    UserActivity ua
WHERE 
    ua.PostCount > 0
ORDER BY 
    ua.PostCount DESC,
    ua.UpVotes DESC
LIMIT 10;