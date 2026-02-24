
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId IN (1, 2)  
),
UserEngagement AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment AS CloseReason 
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10  
),
TopEngagedUsers AS (
    SELECT 
        ue.UserId, 
        ue.DisplayName,
        ue.UpVotes,
        ue.CommentCount,
        ue.GoldBadges,
        ROW_NUMBER() OVER (ORDER BY ue.UpVotes DESC, ue.CommentCount DESC) AS UserRank
    FROM 
        UserEngagement ue
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    cu.DisplayName AS ClosedByUser,
    cp.CloseReason,
    tu.DisplayName AS TopUser,
    tu.UpVotes AS TopUserUpVotes,
    tu.CommentCount AS TopUserComments
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
LEFT JOIN 
    Users cu ON CAST(cp.CloseReason AS JSON) ->> 'UserId' = CAST(cu.Id AS TEXT)  
JOIN 
    TopEngagedUsers tu ON tu.UserRank <= 10
WHERE 
    rp.rn = 1  
ORDER BY 
    rp.CreationDate DESC, rp.Score DESC;
