
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATE '2024-10-01' - INTERVAL '1 year' 
        AND p.PostTypeId IN (1, 2) 
), 
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes, 
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes 
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 1000 
    GROUP BY 
        u.Id, u.DisplayName
),
TopEngagedUsers AS (
    SELECT 
        ue.UserId,
        ue.DisplayName,
        ue.TotalPosts,
        ue.UpVotes,
        ue.DownVotes,
        RANK() OVER (ORDER BY ue.UpVotes - ue.DownVotes DESC) AS EngagementRank
    FROM 
        UserEngagement ue
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CreationDate,
    teu.DisplayName AS TopUser,
    teu.UpVotes AS UserUpVotes,
    teu.DownVotes AS UserDownVotes,
    teu.TotalPosts AS UserTotalPosts
FROM 
    RankedPosts rp
JOIN 
    TopEngagedUsers teu ON rp.Score > 0
WHERE 
    rp.Rank <= 5 
ORDER BY 
    rp.CreationDate DESC, 
    rp.Score DESC;
