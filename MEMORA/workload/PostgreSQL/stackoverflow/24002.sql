WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.OwnerUserId,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS OwnerPostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostScore AS (
    SELECT 
        PostId,
        Score,
        ViewCount,
        CASE 
            WHEN Score > 0 THEN 'Positive'
            WHEN Score < 0 THEN 'Negative'
            ELSE 'Neutral'
        END AS ScoreCategory
    FROM 
        RankedPosts
),
PostInteractions AS (
    SELECT 
        RP.PostId,
        COALESCE(COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END), 0) AS UpVotes,
        COALESCE(COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END), 0) AS DownVotes,
        COALESCE(COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END), 0) AS CommentCount
    FROM 
        RankedPosts RP
    LEFT JOIN 
        Votes V ON RP.PostId = V.PostId
    LEFT JOIN 
        Comments C ON RP.PostId = C.PostId
    GROUP BY 
        RP.PostId
),
FinalSummary AS (
    SELECT 
        PS.PostId,
        PS.Score,
        PS.ViewCount,
        PS.ScoreCategory,
        PI.UpVotes,
        PI.DownVotes,
        PI.CommentCount,
        RP.OwnerDisplayName,
        CASE 
            WHEN PI.UpVotes IS NULL AND PI.DownVotes IS NULL THEN 'No Interactions'
            WHEN PI.UpVotes > PI.DownVotes THEN 'Positive Engagement'
            WHEN PI.UpVotes < PI.DownVotes THEN 'Negative Engagement'
            ELSE 'Balanced Engagement'
        END AS InteractionSummary
    FROM 
        PostScore PS
    JOIN 
        PostInteractions PI ON PS.PostId = PI.PostId
    JOIN 
        RankedPosts RP ON PS.PostId = RP.PostId
)
SELECT 
    FS.OwnerDisplayName,
    COUNT(*) AS PostCount,
    SUM(FS.UpVotes) AS TotalUpVotes,
    SUM(FS.DownVotes) AS TotalDownVotes,
    AVG(FS.Score) AS AverageScore,
    COUNT(CASE WHEN FS.InteractionSummary = 'Positive Engagement' THEN 1 END) AS PositiveEngagementCount,
    COUNT(CASE WHEN FS.InteractionSummary = 'Negative Engagement' THEN 1 END) AS NegativeEngagementCount,
    COUNT(CASE WHEN FS.InteractionSummary = 'Balanced Engagement' THEN 1 END) AS BalancedEngagementCount,
    COUNT(CASE WHEN FS.InteractionSummary = 'No Interactions' THEN 1 END) AS NoInteractionsCount
FROM 
    FinalSummary FS
GROUP BY 
    FS.OwnerDisplayName
HAVING 
    SUM(FS.UpVotes) > SUM(FS.DownVotes) + 10 OR
    AVG(FS.Score) < -5
ORDER BY 
    PostCount DESC, 
    TotalUpVotes DESC NULLS LAST;