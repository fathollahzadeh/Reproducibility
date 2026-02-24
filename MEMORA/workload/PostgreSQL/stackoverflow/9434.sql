
WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        CreationDate,
        LastAccessDate,
        WebsiteUrl,
        Location,
        CASE 
            WHEN Reputation >= 10000 THEN 'Gold'
            WHEN Reputation >= 5000 THEN 'Silver'
            WHEN Reputation >= 1000 THEN 'Bronze'
            ELSE 'Newbie'
        END AS ReputationTier
    FROM 
        Users
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.PostTypeId,
        COALESCE(P.AnswerCount, 0) AS Answers,
        COALESCE(P.CommentCount, 0) AS Comments,
        COALESCE(P.ViewCount, 0) AS Views,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END), 0) AS CloseVotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    GROUP BY 
        P.Id, P.Title, P.PostTypeId
),
TopPosts AS (
    SELECT 
        PS.Title,
        PS.Views,
        PS.Answers,
        PS.Comments,
        PS.UpVotes,
        PS.DownVotes,
        UR.ReputationTier
    FROM 
        PostStatistics PS
    JOIN 
        Users U ON PS.PostId IN (SELECT AcceptedAnswerId FROM Posts WHERE OwnerUserId = U.Id)
    JOIN 
        UserReputation UR ON U.Id = UR.UserId
    WHERE 
        PS.Views > 100 AND PS.Answers > 5
    ORDER BY 
        PS.Views DESC, PS.UpVotes DESC
    LIMIT 10
)
SELECT 
    TP.Title,
    TP.Views,
    TP.Answers,
    TP.Comments,
    TP.UpVotes,
    TP.DownVotes,
    TP.ReputationTier
FROM 
    TopPosts TP
ORDER BY 
    TP.ReputationTier DESC;
