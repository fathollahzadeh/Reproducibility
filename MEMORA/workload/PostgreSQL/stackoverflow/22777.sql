WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostVoteCounts AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        (SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - 
         SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END)) AS NetVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
PostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        COALESCE(pvc.UpVotes, 0) AS UpVotes,
        COALESCE(pvc.DownVotes, 0) AS DownVotes,
        COALESCE(pvc.NetVotes, 0) AS NetVotes,
        rp.Score,
        rp.OwnerUserId
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostVoteCounts pvc ON rp.PostId = pvc.PostId
    WHERE 
        rp.rn <= 5 
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(ps.NetVotes) AS TotalVotes,
        COUNT(ps.PostId) AS PostCount
    FROM 
        Users u
    JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        SUM(ps.NetVotes) > 10
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.TotalVotes,
    tu.PostCount,
    ps.Title,
    ps.UpVotes,
    ps.DownVotes,
    ps.NetVotes
FROM 
    TopUsers tu
JOIN 
    PostStats ps ON tu.UserId = ps.OwnerUserId
WHERE 
    ps.NetVotes = (
        SELECT MAX(NetVotes) 
        FROM PostStats ps_inner 
        WHERE ps_inner.OwnerUserId = ps.OwnerUserId
    )
ORDER BY 
    tu.TotalVotes DESC, 
    ps.CreationDate DESC;