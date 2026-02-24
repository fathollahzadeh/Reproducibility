
WITH PostCounts AS (
    SELECT 
        PostTypeId,
        COUNT(*) AS TotalPosts,
        AVG(ViewCount) AS AvgViews,
        AVG(Score) AS AvgScore
    FROM 
        Posts
    GROUP BY 
        PostTypeId
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.Views,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.Reputation, U.Views
),
VoteStats AS (
    SELECT 
        PostId,
        COUNT(*) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes V
    GROUP BY 
        PostId
)

SELECT 
    PCT.PostTypeId,
    PCT.TotalPosts,
    PCT.AvgViews,
    PCT.AvgScore,
    COUNT(DISTINCT US.UserId) AS TotalUsers,
    AVG(US.Reputation) AS AvgUserReputation,
    SUM(US.BadgeCount) AS TotalBadges,
    COALESCE(SUM(VS.TotalVotes), 0) AS TotalPostVotes,
    COALESCE(SUM(VS.UpVotes), 0) AS TotalUpVotes,
    COALESCE(SUM(VS.DownVotes), 0) AS TotalDownVotes
FROM 
    PostCounts PCT
LEFT JOIN 
    UserStats US ON US.Views > 1000  
LEFT JOIN 
    VoteStats VS ON VS.PostId IN (SELECT Id FROM Posts WHERE PostTypeId = PCT.PostTypeId)
GROUP BY 
    PCT.PostTypeId, PCT.TotalPosts, PCT.AvgViews, PCT.AvgScore
ORDER BY 
    PCT.PostTypeId;
