
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.AcceptedAnswerId,
        p.OwnerUserId,
        u.DisplayName AS OwnerUserDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.AcceptedAnswerId, p.OwnerUserId, u.DisplayName
),
RecentPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        OwnerUserDisplayName,
        CommentCount,
        UpVoteCount,
        DownVoteCount,
        (UpVoteCount - DownVoteCount) AS Score,
        UserPostRank
    FROM 
        RankedPosts
    WHERE 
        CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
),
PostStatistics AS (
    SELECT 
        RP.OwnerUserDisplayName,
        AVG(Score) AS AverageScore,
        COUNT(RP.PostId) AS TotalPosts,
        SUM(RP.CommentCount) AS TotalComments
    FROM 
        RecentPosts RP
    GROUP BY 
        RP.OwnerUserDisplayName
)
SELECT 
    PS.OwnerUserDisplayName,
    PS.TotalPosts,
    PS.TotalComments,
    PS.AverageScore,
    RANK() OVER (ORDER BY PS.AverageScore DESC) AS Rank
FROM 
    PostStatistics PS
WHERE 
    PS.TotalPosts > 0
ORDER BY 
    Rank;
