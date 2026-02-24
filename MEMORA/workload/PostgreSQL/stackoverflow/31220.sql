
WITH RECURSIVE UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        AVG(u.Reputation) AS AvgReputation,
        ROW_NUMBER() OVER (ORDER BY COUNT(p.Id) DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName,
        PostCount,
        Questions,
        Answers,
        AvgReputation,
        Rank
    FROM 
        UserPostStats
    WHERE 
        Rank <= 10
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE((SELECT AVG(C.Score) 
                   FROM Comments C 
                   WHERE C.PostId = p.Id), 0) AS AvgCommentScore,
        COUNT(DISTINCT COALESCE(v.UserId, -1)) AS VoteCount,
        ARRAY_AGG(DISTINCT COALESCE(b.Name, 'No Badge')) AS UserBadges,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON b.UserId = p.OwnerUserId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
),
PostMetrics AS (
    SELECT 
        pa.PostId,
        pa.Title,
        pa.CreationDate,
        pa.ViewCount,
        pa.Score,
        pa.AvgCommentScore,
        pa.VoteCount,
        COALESCE(u.DisplayName, 'Anonymous') AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        pa.OwnerUserId
    FROM 
        PostActivity pa
    LEFT JOIN 
        Users u ON pa.OwnerUserId = u.Id
),
RankedPostMetrics AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY Score DESC, ViewCount DESC) AS PostRank
    FROM 
        PostMetrics
)
SELECT 
    tu.DisplayName AS TopUser,
    rpm.Title,
    rpm.CreationDate,
    rpm.ViewCount,
    rpm.Score,
    rpm.AvgCommentScore,
    rpm.VoteCount,
    rpm.OwnerDisplayName,
    rpm.OwnerReputation
FROM 
    TopUsers tu
JOIN 
    RankedPostMetrics rpm ON tu.UserId = rpm.OwnerUserId
WHERE 
    rpm.PostRank <= 10
ORDER BY 
    tu.Rank, rpm.Score DESC;
