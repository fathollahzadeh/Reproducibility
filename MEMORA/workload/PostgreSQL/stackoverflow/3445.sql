
WITH PostStats AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.Title,
        Users.DisplayName AS Owner,
        COUNT(DISTINCT Comments.Id) AS TotalComments,
        COUNT(DISTINCT Votes.Id) FILTER (WHERE Votes.VoteTypeId = 2) AS Upvotes,
        COUNT(DISTINCT Votes.Id) FILTER (WHERE Votes.VoteTypeId = 3) AS Downvotes,
        MAX(Comments.CreationDate) AS LastCommentDate
    FROM 
        Posts
    LEFT JOIN 
        Users ON Posts.OwnerUserId = Users.Id
    LEFT JOIN 
        Comments ON Posts.Id = Comments.PostId
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    WHERE 
        Posts.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        Posts.Id, Posts.Title, Users.DisplayName
),
PostHistoryDetails AS (
    SELECT 
        PH.PostId,
        PHT.Name AS ChangeType,
        COUNT(*) AS ChangeCount,
        ARRAY_AGG(DISTINCT PH.UserDisplayName) AS UsersInvolved
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    WHERE 
        PH.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 months'
    GROUP BY 
        PH.PostId, PHT.Name
),
CombinedResults AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.Owner,
        PS.TotalComments,
        PS.Upvotes,
        PS.Downvotes,
        PS.LastCommentDate,
        COALESCE(PHD.ChangeCount, 0) AS TotalChanges,
        COALESCE(PHD.UsersInvolved, ARRAY[]::text[]) AS UsersInvolved
    FROM 
        PostStats PS
    LEFT JOIN 
        PostHistoryDetails PHD ON PS.PostId = PHD.PostId
)
SELECT 
    CR.*,
    (CR.Upvotes - CR.Downvotes) AS NetVotes,
    CASE 
        WHEN CR.TotalComments > 10 THEN 'Hot Topic'
        WHEN CR.TotalComments BETWEEN 5 AND 10 THEN 'Moderate Interest'
        ELSE 'Low Interest'
    END AS InterestLevel
FROM 
    CombinedResults CR
ORDER BY 
    NetVotes DESC, LastCommentDate DESC;
